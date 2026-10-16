# TICOH BOT HOSTING

Mobile-first hosting dashboard starter for GitHub + Vercel.

## What works in this starter
- Responsive dark/light dashboard and mobile navigation.
- Pricing cards with unlimited **server/bot records** across all example plans.
- Server record creation, search, and deletion in browser local storage.
- Supabase email/password sign-in and sign-up when configured.
- Supabase starter schema with owner-scoped Row Level Security.
- Honest backend connection states: runtime actions, file storage, live metrics, billing, and deployments are not falsely simulated.

## What is not yet connected
This repository is a dashboard starter, not a production bot execution service. It does not run uploaded code. To support persistent bots, add a separate, secured worker service using isolated containers or equivalent sandboxing. Implement authenticated API routes for create/start/stop/restart/deploy, real log streaming, file storage, resource metering, and backups. Never run arbitrary user code inside a public Vercel request handler.

## Run locally
1. Install Node.js 20+.
2. Copy `.env.example` to `.env`.
3. Add the Supabase project URL and publishable/anon key, or leave them blank to preview the UI.
4. Run:
   ```bash
   npm install
   npm run dev
   ```
5. Open the local URL printed by Vite.

## Supabase setup
1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. In Authentication settings, configure your allowed site URLs and email verification.
4. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to `.env` and Vercel environment variables.
5. The frontend key is public. Never use a service-role key in browser code.

Review and test RLS policies before production. Add a trusted profile-creation trigger if you need automatic profile rows. Admin roles must be enforced server-side and must not be user-editable.

## Deploy to GitHub + Vercel
1. Create a GitHub repository and upload these files.
2. Import the repository into Vercel.
3. Vercel should detect Vite; build command `npm run build`, output directory `dist`.
4. Add the two public Supabase environment variables in Vercel.
5. Redeploy after changing environment variables.

## Unlimited plan wording
The plan UI promises unlimited server records and bot project records. It does not promise infinite CPU, RAM, storage, or concurrent runtime capacity. Publish actual resource allocations and fair-use policies clearly.

## Production checklist
- [ ] Separate persistent execution worker deployed.
- [ ] Strong user-to-server authorization on every worker API endpoint.
- [ ] Container sandboxing, filesystem isolation, network restrictions, and resource quotas.
- [ ] ZIP validation, path traversal prevention, archive size limits, and malware/abuse controls.
- [ ] Secrets stored encrypted or in a secret manager; never returned to clients.
- [ ] WebSocket/SSE logs authenticated and scoped per server.
- [ ] Real resource metrics and status reconciliation.
- [ ] Payment gateway with signed server-side webhook verification.
- [ ] Backups and restore tests.
- [ ] Rate limits, audit logs, incident response, privacy policy, and terms.
- [ ] Test on Android Chrome and installed PWA.

## Notes
- Server records are currently stored in the browser, so they do not sync between devices. Persist them through the Supabase API after sign-in.
- “Online” is not assigned to local records by this starter. Runtime status must be written by a trusted worker.
- Pricing is example content and should be reviewed before accepting customers.
