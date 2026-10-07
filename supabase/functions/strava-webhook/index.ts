// Strava's webhook (README §12): answers the subscription check, and deletes an athlete's tokens
// when they revoke access on Strava (Strava API Policy §7.4). Must answer within 2 s.
//
// Secrets: STRAVA_WEBHOOK_VERIFY_TOKEN (any random string, also given when subscribing) and
// STRAVA_WEBHOOK_SUBSCRIPTION_ID (the `id` Strava returns for the subscription).

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { deleteConnection } from "../_shared/connections.ts";
import { deauthorizedAthlete, subscriptionChallenge } from "../_shared/strava.ts";

export default {
  // Strava calls without credentials.
  fetch: withSupabase({ auth: "none" }, async (req, ctx) => {
    if (req.method === "GET") {
      const answer = subscriptionChallenge(new URL(req.url), Deno.env.get("STRAVA_WEBHOOK_VERIFY_TOKEN") ?? "");
      return answer ? Response.json(answer) : Response.json({ error: "forbidden" }, { status: 403 });
    }

    const event = await req.json().catch(() => undefined);
    const athleteID = deauthorizedAthlete(event, Deno.env.get("STRAVA_WEBHOOK_SUBSCRIPTION_ID") ?? "");
    if (athleteID !== undefined) {
      await deleteConnection(ctx.supabaseAdmin, { athleteID })
        .catch((error) => console.error("Deleting a deauthorized connection failed", error));
    }
    // Acknowledge everything, or Strava retries.
    return Response.json({ received: true });
  }),
};
