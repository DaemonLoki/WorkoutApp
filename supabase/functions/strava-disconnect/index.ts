// Disconnects Strava: revokes the app's access at Strava, then deletes the tokens (README §12).
// Sessions and their upload marks stay.
//
// Secrets: STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { deleteConnection, failure, loadConnection, notConfigured, unauthorized } from "../_shared/connections.ts";
import { revoke, stravaFromEnvironment } from "../_shared/strava.ts";

export default {
  fetch: withSupabase({ auth: "user" }, async (_req, ctx) => {
    const userID = ctx.userClaims?.id;
    if (!userID) return unauthorized();
    const strava = stravaFromEnvironment();
    if (!strava) return notConfigured();

    try {
      const connection = await loadConnection(ctx.supabaseAdmin, userID);
      if (connection) await revoke(strava, connection.refreshToken);
      await deleteConnection(ctx.supabaseAdmin, { userID });
      return Response.json({ disconnected: true });
    } catch (error) {
      return failure(error);
    }
  }),
};
