# KD Games

Browser game at [game.krackeddevs.com](https://game.krackeddevs.com/).

## Discord sign-in and presence

KD Discord members can sign in and see other signed-in members in the same game room. Discord provides the displayed name and avatar. Character movement, appearance and shared nonlethal hits are synchronized. Shots on live members trigger a flash, brief flinch, impact sound and reaction bubble while preserving their health and position. NPC simulation runs in each browser.

The backend reuses the KD Square OAuth application and checks membership in guild `1445246968367677573`. Its registered game callback is `https://game.krackeddevs.com/auth/callback`.

## Checks

From `server`, run `npm ci` and `npm test`. The tests exercise OAuth state, membership checks, session revocation, room presence, duplicate tabs and the previous-domain redirect.

## Deploy

The static Cloudflare Pages project is `kd-games-platform`. Upload `index.html`, `discord-presence.js`, and `assets/kd-logo.png` together in a clean publish directory using `wrangler pages deploy <publish-directory> --project-name kd-games-platform --branch main`.

The Worker configuration is `server/wrangler.jsonc`. From `server`, deploy it with `npx wrangler deploy`. The `DISCORD_CLIENT_SECRET` secret must be configured with `npx wrangler secret put DISCORD_CLIENT_SECRET`. Keep its value outside the repository and browser code.

The Worker handles `/auth/*` and `/api/*` on the game domain. The previous `platform.danialalias.com` address redirects to the new domain.

GitHub pushes require a separate deployment to publish changes.

## Branding

`assets/kd-logo.png` is the official KrackedDevs transparent logo, sourced from the existing KD website asset `https://krackeddevs.com/landing-v3/kd-logo-t.png`. The canvas crops its transparent margin when drawing; the source artwork is unchanged.
