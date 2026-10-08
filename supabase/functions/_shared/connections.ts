// The strava_connections table and the answers every strava-* function shares (README §12).

import type { SupabaseContext } from "@supabase/server";
import { AthleteLimitError, type Connection, type Grant, StravaError } from "./strava.ts";

type Admin = SupabaseContext["supabaseAdmin"];

/** What the app may know about its connection; tokens never leave the server. */
export interface ConnectionSummary {
  connected_at: string;
  auto_upload: boolean;
}

/** Stores a grant; one Strava athlete belongs to one account, and reconnecting keeps `created_at`. */
export async function saveGrant(admin: Admin, userID: string, grant: Grant): Promise<ConnectionSummary> {
  const deleted = await admin.from("strava_connections").delete()
    .eq("athlete_id", grant.athleteID).neq("user_id", userID);
  if (deleted.error) throw deleted.error;
  const { data, error } = await admin.from("strava_connections").upsert({
    user_id: userID,
    athlete_id: grant.athleteID,
    scope: grant.scope,
    ...tokenColumns(grant.connection),
  }, { onConflict: "user_id" }).select("created_at, auto_upload").single();
  if (error) throw error;
  return { connected_at: data.created_at, auto_upload: data.auto_upload };
}

export async function loadConnection(admin: Admin, userID: string): Promise<Connection | undefined> {
  const { data, error } = await admin.from("strava_connections")
    .select("access_token, refresh_token, expires_at").eq("user_id", userID).maybeSingle();
  if (error) throw error;
  if (!data) return undefined;
  return { accessToken: data.access_token, refreshToken: data.refresh_token, expiresAt: new Date(data.expires_at) };
}

/** Must follow every refresh: Strava may have rotated the refresh token. */
export async function saveTokens(admin: Admin, userID: string, connection: Connection): Promise<void> {
  const { error } = await admin.from("strava_connections").update(tokenColumns(connection)).eq("user_id", userID);
  if (error) throw error;
}

export async function deleteConnection(admin: Admin, match: { userID: string } | { athleteID: number }) {
  const query = admin.from("strava_connections").delete();
  const { error } = "userID" in match
    ? await query.eq("user_id", match.userID)
    : await query.eq("athlete_id", match.athleteID);
  if (error) throw error;
}

function tokenColumns(connection: Connection) {
  return {
    access_token: connection.accessToken,
    refresh_token: connection.refreshToken,
    expires_at: connection.expiresAt.toISOString(),
    updated_at: new Date().toISOString(),
  };
}

/**
 * Error codes the app tells apart: `not_connected`, `athlete_limit`, `rate_limited`, `strava_rejected`,
 * `strava_failed`.
 */
export function failure(error: unknown): Response {
  if (error instanceof AthleteLimitError) {
    console.error("Strava's athlete capacity is used up", error.detail);
    return Response.json({ error: "athlete_limit" }, { status: 409 });
  }
  if (error instanceof StravaError) {
    console.error("Strava request failed", error.status, error.detail);
    if (error.status === 429) return Response.json({ error: "rate_limited" }, { status: 503 });
    if (error.status === 400 || error.status === 403) {
      return Response.json({ error: "strava_rejected", detail: error.detail }, { status: 422 });
    }
    return Response.json({ error: "strava_failed" }, { status: 502 });
  }
  console.error("strava function failed", error);
  return Response.json({ error: "internal" }, { status: 500 });
}

export const notConfigured = () => Response.json({ error: "strava_not_configured" }, { status: 503 });
export const notConnected = () => Response.json({ error: "not_connected" }, { status: 404 });
export const unauthorized = () => Response.json({ error: "unauthorized" }, { status: 401 });
