// Uploads one finished Session to Strava as a WeightTraining activity (README §12). The app builds
// the file (`StravaUpload`); this adds the token, refreshing it first when needed, and waits for
// Strava to process the upload. Answers `{ activity_id }` or `{ status: "processing" }`.
//
// Secrets: STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import {
  deleteConnection,
  failure,
  loadConnection,
  notConfigured,
  notConnected,
  saveTokens,
  unauthorized,
} from "../_shared/connections.ts";
import { freshTokens, StravaError, stravaFromEnvironment, upload } from "../_shared/strava.ts";

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    const userID = ctx.userClaims?.id;
    if (!userID) return unauthorized();
    const strava = stravaFromEnvironment();
    if (!strava) return notConfigured();

    const { session_id: sessionID, name, file } = await req.json().catch(() => ({}));
    if (typeof sessionID !== "string" || typeof name !== "string" || !Array.isArray(file?.sets)) {
      return Response.json({ error: "invalid_upload" }, { status: 400 });
    }
    try {
      let connection = await loadConnection(ctx.supabaseAdmin, userID);
      if (!connection) return notConnected();
      const fresh = await freshTokens(strava, connection);
      if (fresh) {
        await saveTokens(ctx.supabaseAdmin, userID, fresh);
        connection = fresh;
      }
      const outcome = await upload(strava, connection.accessToken, { sessionID, name, file });
      return Response.json("activityID" in outcome ? { activity_id: outcome.activityID } : { status: "processing" });
    } catch (error) {
      if (error instanceof StravaError && error.status === 401) {
        // The athlete revoked access on Strava and the webhook hasn't told us yet.
        await deleteConnection(ctx.supabaseAdmin, { userID }).catch(() => {});
        return notConnected();
      }
      return failure(error);
    }
  }),
};
