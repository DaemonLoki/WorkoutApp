// Strava's OAuth, upload and webhook rules (README §12) against a stubbed fetch. Run with
// `deno test --allow-env supabase/functions`.

import { assertEquals, assertRejects } from "jsr:@std/assert@^1";
import {
  AthleteLimitError,
  type Connection,
  deauthorizedAthlete,
  exchangeCode,
  freshTokens,
  revoke,
  type Strava,
  subscriptionChallenge,
  upload,
} from "./strava.ts";

/** Answers each request with the next response and remembers what was asked. */
function stubbedStrava(...responses: Response[]) {
  const requests: Request[] = [];
  const strava: Strava = {
    clientID: "12345",
    clientSecret: "client-secret",
    fetch: (input, init) => {
      requests.push(new Request(input, init));
      const response = responses.shift();
      if (!response) throw new Error(`unexpected request to ${requests.at(-1)?.url}`);
      return Promise.resolve(response);
    },
    sleep: () => Promise.resolve(),
    now: () => new Date("2026-10-06T12:00:00Z"),
  };
  return { strava, requests };
}

const connection: Connection = {
  accessToken: "old-access",
  refreshToken: "old-refresh",
  expiresAt: new Date("2026-10-06T12:30:00Z"),
};

Deno.test("a token expiring within the hour is refreshed and the rotated refresh token kept", async () => {
  const { strava, requests } = stubbedStrava(
    Response.json({ access_token: "new-access", refresh_token: "new-refresh", expires_at: 1791320400 }),
  );

  const fresh = await freshTokens(strava, connection);

  assertEquals(fresh, {
    accessToken: "new-access",
    refreshToken: "new-refresh",
    expiresAt: new Date(1791320400 * 1000),
  });
  const form = await requests[0].formData();
  assertEquals(requests[0].url, "https://www.strava.com/oauth/token");
  assertEquals(form.get("grant_type"), "refresh_token");
  assertEquals(form.get("refresh_token"), "old-refresh");
});

Deno.test("a token valid for more than an hour is used as it is", async () => {
  const { strava, requests } = stubbedStrava();

  const fresh = await freshTokens(strava, { ...connection, expiresAt: new Date("2026-10-06T14:00:00Z") });

  assertEquals(fresh, undefined);
  assertEquals(requests.length, 0);
});

const session = {
  sessionID: "40000000-0000-0000-0000-000000000001",
  name: "Leg Day",
  file: { version: "1.0", sets: [{ exercise_type: "BARBELL_BACK_SQUAT", repetitions: 5, weight: 80 }] },
};
const processing = { id: 111, id_str: "111", status: "Your activity is still being processed.", activity_id: null };

Deno.test("an upload is a WeightTraining JSON file polled until Strava made the activity", async () => {
  const { strava, requests } = stubbedStrava(
    Response.json(processing, { status: 201 }),
    Response.json(processing),
    Response.json({ ...processing, status: "Your activity is ready.", activity_id: 16000000001 }),
  );

  const outcome = await upload(strava, "access", session);

  assertEquals(outcome, { activityID: 16000000001 });
  const post = requests[0];
  assertEquals([post.method, post.url], ["POST", "https://www.strava.com/api/v3/uploads"]);
  assertEquals(post.headers.get("Authorization"), "Bearer access");
  const form = await post.formData();
  assertEquals(form.get("data_type"), "json");
  assertEquals(form.get("sport_type"), "WeightTraining");
  assertEquals(form.get("name"), "Leg Day");
  assertEquals(form.get("external_id"), session.sessionID);
  assertEquals(JSON.parse(await (form.get("file") as File).text()), session.file);
  assertEquals(requests.slice(1).map((request) => request.url), [
    "https://www.strava.com/api/v3/uploads/111",
    "https://www.strava.com/api/v3/uploads/111",
  ]);
});

// An earlier upload of the same Session reached Strava, but its answer never reached the app.
Deno.test("a duplicate of an earlier upload counts as that activity", async () => {
  const { strava } = stubbedStrava(
    Response.json(processing, { status: 201 }),
    Response.json({
      ...processing,
      status: "There was an error processing your activity.",
      error:
        "40000000-0000-0000-0000-000000000001.json duplicate of <a href='/activities/21234316'>activity 21234316</a>",
    }),
  );

  assertEquals(await upload(strava, "access", session), { activityID: 21234316 });
});

Deno.test("an upload Strava is still processing after ten seconds is left for later", async () => {
  const { strava, requests } = stubbedStrava(
    Response.json(processing, { status: 201 }),
    ...Array.from({ length: 10 }, () => Response.json(processing)),
  );

  assertEquals(await upload(strava, "access", session), { stillProcessing: true });
  assertEquals(requests.length, 11);
});

Deno.test("the webhook answers Strava's subscription check only with the right verify token", () => {
  const check = (token: string) =>
    new URL(
      `https://example.supabase.co/functions/v1/strava-webhook?hub.mode=subscribe&hub.challenge=15f7d1a91c1f40f8a748fd134752feb3&hub.verify_token=${token}`,
    );

  assertEquals(subscriptionChallenge(check("our-token"), "our-token"), {
    "hub.challenge": "15f7d1a91c1f40f8a748fd134752feb3",
  });
  assertEquals(subscriptionChallenge(check("guess"), "our-token"), undefined);
});

Deno.test("a deauthorization event names the athlete whose tokens must go", () => {
  const event = {
    aspect_type: "update",
    event_time: 1791320400,
    object_id: 1234567,
    object_type: "athlete",
    owner_id: 1234567,
    subscription_id: 120475,
    updates: { authorized: "false" },
  };

  assertEquals(deauthorizedAthlete(event, "120475"), 1234567);
  assertEquals(deauthorizedAthlete(event, "999"), undefined, "an event for another subscription");
  assertEquals(
    deauthorizedAthlete({ ...event, object_type: "activity", updates: { title: "Leg Day" } }, "120475"),
    undefined,
    "an activity event",
  );
});

const tokenResponse = {
  token_type: "Bearer",
  access_token: "access",
  refresh_token: "refresh",
  expires_at: 1791320400,
  expires_in: 21600,
  scope: "read,activity:write",
  athlete: { id: 1234567, firstname: "Stefan" },
};

Deno.test("the one-time code becomes tokens and the athlete they belong to", async () => {
  const { strava, requests } = stubbedStrava(Response.json(tokenResponse));

  const grant = await exchangeCode(strava, "abc123");

  assertEquals(grant, {
    athleteID: 1234567,
    scope: "read,activity:write",
    connection: { accessToken: "access", refreshToken: "refresh", expiresAt: new Date(1791320400 * 1000) },
  });
  const form = await requests[0].formData();
  assertEquals([form.get("grant_type"), form.get("code"), form.get("client_secret")], [
    "authorization_code",
    "abc123",
    "client-secret",
  ]);
});

// Strava's token answer separates scopes with spaces (docs), its redirect with commas.
Deno.test("a grant with space-separated scopes, as Strava documents it, is accepted", async () => {
  const { strava } = stubbedStrava(Response.json({ ...tokenResponse, scope: "activity:read activity:write" }));

  const grant = await exchangeCode(strava, "abc123");

  assertEquals([grant.athleteID, grant.scope], [1234567, "activity:read activity:write"]);
});

Deno.test("a grant without permission to upload is refused", async () => {
  const { strava } = stubbedStrava(Response.json({ ...tokenResponse, scope: "read" }));

  await assertRejects(() => exchangeCode(strava, "abc123"), Error, "activity:write");
});

// Strava doesn't document this answer; the text is what developers report (docs/research/strava-athlete-capacity.md §4).
Deno.test("a token exchange refused for the athlete limit is told apart", async () => {
  const { strava } = stubbedStrava(
    Response.json({ message: "Limit of connected athletes exceeded", errors: [] }, { status: 403 }),
  );

  await assertRejects(() => exchangeCode(strava, "abc123"), AthleteLimitError);
});

Deno.test("any other refused token exchange is not an athlete-limit error", async () => {
  const { strava } = stubbedStrava(
    Response.json({ message: "Bad Request", errors: [{ field: "code", code: "invalid" }] }, { status: 400 }),
  );

  const error = await assertRejects(() => exchangeCode(strava, "abc123"));
  assertEquals(error instanceof AthleteLimitError, false);
});

Deno.test("disconnecting revokes the refresh token with the app's credentials", async () => {
  const { strava, requests } = stubbedStrava(new Response(null, { status: 200 }));

  await revoke(strava, "refresh");

  assertEquals(requests[0].url, "https://www.strava.com/oauth/revoke");
  assertEquals(requests[0].headers.get("Authorization"), `Basic ${btoa("12345:client-secret")}`);
  const form = await requests[0].formData();
  assertEquals([form.get("token"), form.get("token_type_hint")], ["refresh", "refresh_token"]);
});
