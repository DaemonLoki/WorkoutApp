// Talking to Strava for the strava-* functions (README §12, docs/research/strava-api.md).
// Pure apart from `Strava.fetch`, so the rules are tested against a stubbed fetch.

/** Strava's API base; changes to https://api-v3.strava.com from 2027-01-04 on (changelog 2026-06-01). */
const api = "https://www.strava.com/api/v3";
const oauth = "https://www.strava.com/oauth";

export interface Strava {
  clientID: string;
  clientSecret: string;
  fetch: typeof fetch;
  sleep: (milliseconds: number) => Promise<void>;
  now: () => Date;
}

/** From the STRAVA_CLIENT_ID and STRAVA_CLIENT_SECRET secrets; `undefined` until they are set. */
export function stravaFromEnvironment(): Strava | undefined {
  const clientID = Deno.env.get("STRAVA_CLIENT_ID");
  const clientSecret = Deno.env.get("STRAVA_CLIENT_SECRET");
  if (!clientID || !clientSecret) return undefined;
  return {
    clientID,
    clientSecret,
    fetch: (input, init) => fetch(input, init),
    sleep: (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds)),
    now: () => new Date(),
  };
}

export interface Connection {
  accessToken: string;
  refreshToken: string;
  expiresAt: Date;
}

export class StravaError extends Error {
  constructor(readonly status: number, readonly detail: string) {
    super(`Strava answered ${status}: ${detail}`);
  }
}

/**
 * Strava refuses new athletes once the API app's athlete capacity is used up. Undocumented; matched
 * on the text developers report (docs/research/strava-athlete-capacity.md §4).
 */
export class AthleteLimitError extends StravaError {
  static matches(status: number, detail: string): boolean {
    return status === 403 && /limit of connected athletes|too many athletes/i.test(detail);
  }
}

export interface Grant {
  athleteID: number;
  scope: string;
  connection: Connection;
}

/** Swaps the one-time code from Strava's redirect for tokens; uploads need `activity:write`. */
export async function exchangeCode(strava: Strava, code: string): Promise<Grant> {
  const tokens = await tokenRequest(strava, { grant_type: "authorization_code", code });
  const scope = String(tokens.scope ?? "");
  // The token answer separates scopes with spaces, the redirect with commas; accept either.
  if (!scope.split(/[\s,]+/).includes("activity:write")) {
    throw new StravaError(403, `granted "${scope}" without activity:write`);
  }
  return { athleteID: tokens.athlete.id, scope, connection: connectionFrom(tokens) };
}

/** Revokes the app's access for the athlete; Strava answers 200 even for an unknown token. */
export async function revoke(strava: Strava, refreshToken: string): Promise<void> {
  const response = await strava.fetch(`${oauth}/revoke`, {
    method: "POST",
    headers: { Authorization: `Basic ${btoa(`${strava.clientID}:${strava.clientSecret}`)}` },
    body: new URLSearchParams({ token: refreshToken, token_type_hint: "refresh_token" }),
  });
  if (!response.ok) throw new StravaError(response.status, await response.text());
}

/**
 * New tokens when the access token expires within the hour, else `undefined`. Strava may rotate
 * the refresh token; the old one stops working at once, so the caller must store the result.
 */
export async function freshTokens(strava: Strava, connection: Connection): Promise<Connection | undefined> {
  const hour = 60 * 60 * 1000;
  if (connection.expiresAt.getTime() - strava.now().getTime() > hour) return undefined;
  const tokens = await tokenRequest(strava, {
    grant_type: "refresh_token",
    refresh_token: connection.refreshToken,
  });
  return connectionFrom(tokens);
}

async function tokenRequest(strava: Strava, fields: Record<string, string>) {
  const response = await strava.fetch(`${oauth}/token`, {
    method: "POST",
    body: new URLSearchParams({ client_id: strava.clientID, client_secret: strava.clientSecret, ...fields }),
  });
  if (!response.ok) {
    const detail = await response.text();
    if (AthleteLimitError.matches(response.status, detail)) throw new AthleteLimitError(response.status, detail);
    throw new StravaError(response.status, detail);
  }
  return await response.json();
}

function connectionFrom(tokens: { access_token: string; refresh_token: string; expires_at: number }): Connection {
  return {
    accessToken: tokens.access_token,
    refreshToken: tokens.refresh_token,
    expiresAt: new Date(tokens.expires_at * 1000),
  };
}

export interface SessionUpload {
  sessionID: string;
  /** The activity's title: the Workout name. */
  name: string;
  /** The app's "Strength Training (Limited)" JSON (`StravaUpload.file()`). */
  file: unknown;
}

/** Strava made the activity, or hadn't finished processing within the polls. */
export type UploadOutcome = { activityID: number } | { stillProcessing: true };

interface UploadStatus {
  id_str: string;
  error: string | null;
  activity_id: number | null;
}

/** Strava takes under 2 s on average; poll once a second, at most this often. */
const polls = 10;

/** Posts the Session as a WeightTraining activity and waits for Strava to process it. */
export async function upload(strava: Strava, accessToken: string, session: SessionUpload): Promise<UploadOutcome> {
  const form = new FormData();
  form.set(
    "file",
    new Blob([JSON.stringify(session.file)], { type: "application/json" }),
    `${session.sessionID}.json`,
  );
  form.set("data_type", "json");
  form.set("sport_type", "WeightTraining");
  form.set("name", session.name);
  form.set("external_id", session.sessionID);
  let status = await uploadRequest(strava, accessToken, `${api}/uploads`, { method: "POST", body: form });

  for (let poll = 0; poll < polls; poll++) {
    const outcome = outcomeOf(status);
    if (outcome) return outcome;
    await strava.sleep(1000);
    status = await uploadRequest(strava, accessToken, `${api}/uploads/${status.id_str}`, {});
  }
  return outcomeOf(status) ?? { stillProcessing: true };
}

async function uploadRequest(strava: Strava, accessToken: string, url: string, init: RequestInit) {
  const response = await strava.fetch(url, { ...init, headers: { Authorization: `Bearer ${accessToken}` } });
  if (!response.ok && response.status !== 400) throw new StravaError(response.status, await response.text());
  return await response.json() as UploadStatus;
}

function outcomeOf(status: UploadStatus): UploadOutcome | undefined {
  if (status.activity_id) return { activityID: status.activity_id };
  if (status.error) {
    // "… duplicate of <a href='/activities/21234316'>activity 21234316</a>": uploaded before.
    const duplicate = status.error.match(/duplicate of .*?activit(?:y|ies)\D*(\d+)/i);
    if (duplicate) return { activityID: Number(duplicate[1]) };
    throw new StravaError(400, status.error);
  }
  return undefined;
}

/** The answer to Strava's GET when creating the push subscription; `undefined` for anyone else. */
export function subscriptionChallenge(url: URL, verifyToken: string): { "hub.challenge": string } | undefined {
  const challenge = url.searchParams.get("hub.challenge");
  if (url.searchParams.get("hub.mode") !== "subscribe" || !challenge) return undefined;
  if (url.searchParams.get("hub.verify_token") !== verifyToken) return undefined;
  return { "hub.challenge": challenge };
}

/**
 * The athlete who revoked access, from a webhook event of our subscription. Strava doesn't sign
 * events, so the subscription ID (STRAVA_WEBHOOK_SUBSCRIPTION_ID) is the check.
 */
export function deauthorizedAthlete(event: unknown, subscriptionID: string): number | undefined {
  if (typeof event !== "object" || event === null) return undefined;
  const { object_type, owner_id, subscription_id, updates } = event as Record<string, unknown>;
  if (String(subscription_id) !== subscriptionID || object_type !== "athlete") return undefined;
  const authorized = (updates as Record<string, unknown> | undefined)?.authorized;
  if (authorized !== "false" && authorized !== false) return undefined;
  return typeof owner_id === "number" ? owner_id : undefined;
}
