// Deletes the signed-in user and, by cascade, every row they own; first revokes their
// Sign in with Apple token (App Review guideline 5.1.1(v); README §14).
//
// The app sends a fresh `authorization_code` from Sign in with Apple, so no Apple token is ever
// stored. Secrets (`supabase secrets set …`): APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY (the .p8
// contents), APPLE_CLIENT_ID (the app's bundle ID).

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { importPKCS8, SignJWT } from "jose";

const apple = "https://appleid.apple.com";

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    const userID = ctx.userClaims?.id;
    if (!userID) return Response.json({ error: "unauthorized" }, { status: 401 });

    const { authorization_code: code } = await req.json().catch(() => ({}));
    if (typeof code !== "string" || code.length === 0) {
      return Response.json({ error: "missing_authorization_code" }, { status: 400 });
    }

    const revocation = await revokeAppleToken(code);
    if (!revocation.ok) {
      console.error("Apple token revocation failed", revocation.detail);
      return Response.json({ error: "apple_revocation_failed" }, { status: 502 });
    }

    const { error } = await ctx.supabaseAdmin.auth.admin.deleteUser(userID);
    if (error) {
      console.error("Deleting the user failed", error.message);
      return Response.json({ error: "delete_failed" }, { status: 500 });
    }
    return Response.json({ deleted: true });
  }),
};

/** Swaps the one-time authorization code for a refresh token, then revokes that token. */
async function revokeAppleToken(code: string): Promise<{ ok: boolean; detail?: string }> {
  const clientID = Deno.env.get("APPLE_CLIENT_ID");
  if (!clientID) return { ok: false, detail: "APPLE_CLIENT_ID is not set" };
  const clientSecret = await makeClientSecret(clientID);
  if (!clientSecret) return { ok: false, detail: "Apple signing key is not configured" };

  const tokenResponse = await fetch(`${apple}/auth/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientID,
      client_secret: clientSecret,
      code,
      grant_type: "authorization_code",
    }),
  });
  if (!tokenResponse.ok) return { ok: false, detail: `token: ${await tokenResponse.text()}` };
  const tokens = await tokenResponse.json();
  const token = tokens.refresh_token ?? tokens.access_token;
  const hint = tokens.refresh_token ? "refresh_token" : "access_token";

  const revokeResponse = await fetch(`${apple}/auth/revoke`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientID,
      client_secret: clientSecret,
      token,
      token_type_hint: hint,
    }),
  });
  if (!revokeResponse.ok) return { ok: false, detail: `revoke: ${await revokeResponse.text()}` };
  return { ok: true };
}

/** The short-lived ES256 JWT Apple takes as `client_secret`. */
async function makeClientSecret(clientID: string): Promise<string | undefined> {
  const teamID = Deno.env.get("APPLE_TEAM_ID");
  const keyID = Deno.env.get("APPLE_KEY_ID");
  const privateKey = Deno.env.get("APPLE_PRIVATE_KEY");
  if (!teamID || !keyID || !privateKey) return undefined;

  const key = await importPKCS8(privateKey.replaceAll("\\n", "\n"), "ES256");
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyID })
    .setIssuer(teamID)
    .setSubject(clientID)
    .setAudience(apple)
    .setIssuedAt()
    .setExpirationTime("5m")
    .sign(key);
}
