// Connects the signed-in user's Strava account: swaps the one-time code from Strava's redirect for
// tokens and stores them where the app can't read them (README §12).
//
// Secrets (`supabase secrets set …`): STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { failure, notConfigured, saveGrant, unauthorized } from "../_shared/connections.ts";
import { exchangeCode, stravaFromEnvironment } from "../_shared/strava.ts";

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    const userID = ctx.userClaims?.id;
    if (!userID) return unauthorized();
    const strava = stravaFromEnvironment();
    if (!strava) return notConfigured();

    const { code } = await req.json().catch(() => ({}));
    if (typeof code !== "string" || code.length === 0) {
      return Response.json({ error: "missing_code" }, { status: 400 });
    }
    try {
      return Response.json(await saveGrant(ctx.supabaseAdmin, userID, await exchangeCode(strava, code)));
    } catch (error) {
      return failure(error);
    }
  }),
};
