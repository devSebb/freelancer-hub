# Pricing & Billing Plan v2

**App:** Freelancer Hub / Billdeck — Rails 7.2, Devise, Postgres, Hotwire, Tailwind  
**Scope:** Plan and spec only. No code in this document.

---

## Direction (for the AI executing this plan)

This section gives another AI the context and constraints needed to execute this plan without breaking the app, while staying on theme and delivering strong UI/UX.

### How not to ruin functionality

- **Do not change** existing tokenized public routes (`p/:token`, `i/:token`) or their controllers/views. Public proposal and invoice viewing must work exactly as today.
- **Do not remove or alter** the existing PDF branding logic that uses `current_user.pro?`. Only the **implementation** of `User#pro?` changes (from hardcoded `false` to subscription-derived); call sites and `show_powered_by: !current_user.pro?` stay as they are.
- **Do not change** Devise routes, sign-up flow, or authentication. Users still sign up for free; limits and billing apply after sign-up.
- **Do not break** existing CRUD for clients, proposals, invoices, and proposal templates. Add **before_action** checks that redirect when at limit; do not remove or replace the core create/update logic.
- **Preserve** existing scoping: all resources remain scoped to `current_user` (e.g. `current_user.clients`, `current_user.proposals`). Billing and limits are additive.
- **Test** after each phase: run the app, sign up, create resources, and confirm redirects and messages before moving on.

### Files you will touch (by phase)

Use this as a checklist. Do not invent new top-level modules or rename existing ones; stay within the existing app structure.

**Phase 1 (Data model + limits):**  
`config/routes.rb` (no new public routes yet; optional route for pricing placeholder), `db/migrate/*` (add `stripe_customer_id` to users; create `subscriptions` table; optionally `webhook_events`), `db/schema.rb` (via migrations), `app/models/user.rb`, `app/models/subscription.rb` (new), `config/plans.yml` (or equivalent plan/limits config), plan limit concern or service (e.g. `app/models/concerns/plan_limits.rb` or `app/services/plan_limits.rb`), `app/controllers/application_controller.rb` or a concern used in resource controllers, `app/controllers/clients_controller.rb`, `app/controllers/proposals_controller.rb`, `app/controllers/invoices_controller.rb`, `app/controllers/proposal_templates_controller.rb` (before_action for limits on `new`/`create`), `config/locales/en.yml`, `config/locales/es.yml` (limit and upgrade messages).

**Phase 2 (Stripe + Billing UI):**  
`Gemfile` (add `stripe`), `config/routes.rb` (checkout create, webhook endpoint, billing), `app/controllers/checkouts_controller.rb` or `billing_controller.rb` (new), `app/controllers/webhooks_controller.rb` (new), `app/controllers/settings_controller.rb` (billing action or data for billing section), `app/views/settings/show.html.erb` (add Billing/Plan section), environment/config for Stripe keys and Price IDs (e.g. `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_STARTER_MONTHLY_PRICE_ID`, etc.), locales for billing copy.

**Phase 3 (Pricing UI + polish):**  
`config/routes.rb` (e.g. `get "pricing"`), `app/controllers/pages_controller.rb` (e.g. `pricing` action), `app/views/pages/home.html.erb` (add or expand pricing section with toggle + 3 cards), `app/views/pages/pricing.html.erb` (new; or under `app/views/pricing/` if you prefer a dedicated resource), `app/views/layouts/landing.html.erb` (only if needed for nav/footer link to Pricing), `config/locales/en.yml`, `config/locales/es.yml` (pricing page, FAQ, CTAs). Any shared partials for plan cards or toggle (optional; keep DRY between landing and /pricing).

### Theme and UI/UX

- **Theme:** The app uses a black/white palette with an accent (e.g. green/accent). Keep the same color variables, typography (e.g. Poppins, Yellowtail for script), and “glass” card style used on the landing and in the authenticated layout. Do not introduce a different visual language for pricing or billing.
- **Landing page:** The pricing section (and the dedicated /pricing page) must feel like a natural part of the existing landing: same background treatments (grid/dot patterns, gradients), same card style, same button and link styling. Plan cards should be scan-friendly, with clear hierarchy (plan name, price, a few bullets, CTA). Avoid long walls of checkmarks; keep bullets concise.
- **Accessibility and responsiveness:** Ensure the Monthly/Yearly toggle and CTAs work on small screens; keep contrast and focus states consistent with the rest of the app.
- **Copy:** Use the exact wording specified in this plan (e.g. “Pay yearly — 1 month free”, “Cancel anytime”, “Secure checkout by Stripe”). Trust and FAQ copy should be clear and consistent in both English and Spanish locales.

### Execution order

- Execute **Phase 1** fully (data model, plan config, limit enforcement). Then **stop** and ask the user to confirm before continuing.
- Execute **Phase 2** fully (Stripe integration, webhooks, Settings → Billing). Then **stop** and ask the user to confirm before continuing.
- Execute **Phase 3** fully (landing pricing section, /pricing page, FAQ, polish). Then stop; the implementation is complete.

Do not skip phases or implement Phase 2 or 3 before Phase 1 is verified by the user.

---

## 0. Guardrails for this plan

- **No code yet** — plan/spec only.
- **Architecture unchanged:** Rails 7.2, Devise, Postgres, Hotwire, Tailwind.
- **Existing behavior preserved:** Tokenized public routes `p/:token` (proposals), `i/:token` (invoices); PDF branding continues to depend on `current_user.pro?` (powered-by shown when `pro?` is false).
- **Billing is webhook-driven:** Entitlement comes from Stripe webhooks, not from checkout success redirects.
- **Resilient to retries and out-of-order events:** Idempotency via stored event IDs; timestamp guard so only the latest valid state is applied; local state is always derived from Stripe, never inferred.

---

## 1. Pricing tiers and limits (definitive business rules)

### 1.1 Tiers and limits (locked)

| Tier     | Price        | Clients   | Proposals | Invoices | Templates | PDF branding      |
|----------|--------------|-----------|-----------|-----------|-----------|--------------------|
| **Free**    | $0           | 4 (total) | 4 / month | 4 / month | 4 (total) | “Powered by …”    |
| **Starter** | $5.99 / month | 30 (total) | 50 / month | 50 / month | 10 (total) | None (`pro?` true) |
| **Pro**     | $10.99 / month | Unlimited | Unlimited | Unlimited | Unlimited | None (`pro?` true) |

### 1.2 Mental model: stock vs flow

- **Stock (total, non-resetting):** **Clients** and **templates**. These are lifetime counts per account. They do not reset. “4 clients” on Free means 4 clients total; “30 clients” on Starter means 30 clients total.
- **Flow (monthly quotas):** **Proposals** and **invoices**. These reset each billing or calendar window. “4 / month” means at most 4 new proposals (and 4 new invoices) in the current window; usage resets at the start of the next window.

### 1.3 What “monthly usage” counts (create vs send vs export)

- **Quota counts created proposals and created invoices only.** Specifically: count records where the proposal or invoice was **created** in the current window (using `created_at` or equivalent).  
- **It does not count:** PDF exports, “send proposal” / “send invoice” actions, or views. If you later introduce “sends per month” or “PDF exports per month,” those must be **separate quotas** and **separate limits** in the plan. Do not mix “creates” with “sends” or “exports” in the same metric; this keeps enforcement and product logic clear for future changes.

### 1.4 Monthly window definition (explicit)

- **Paid users (Starter / Pro):**  
  Monthly quota window = **Stripe billing period**: from `current_period_start` to `current_period_end` on the user’s subscription. Count proposals and invoices whose `created_at` (or equivalent) falls within this interval. The subscription record must store both `current_period_start` and `current_period_end` (synced from Stripe).

- **Free users:**  
  Monthly quota window = **calendar month (UTC)**. Count proposals and invoices created in the current UTC month. No Stripe dependency; simpler than a rolling 30-day window.

- **Reset behavior:** Quota counters for proposals and invoices reset automatically at the start of each new window (start of next Stripe billing period for paid users; start of next UTC month for free users). No manual reset is required.

---

## 2. Annual billing: copy and Stripe price definition (locked)

### 2.1 Copy

- **CTA for yearly:** Use **“Pay yearly — 1 month free”** everywhere. Do not use “Start free month (yearly)” or similar.
- **Meaning (must be explicit in UI/copy):**
  - This is a **discount** (pay for 11 months, get 12), not a free trial.
  - The user is **billed immediately** for the full yearly amount when they choose yearly.

### 2.2 Yearly price formula and display

- **Formula:** `yearly_price = monthly_price × 11`.
  - Starter yearly: $5.99 × 11 = **$65.89 / year**.
  - Pro yearly: $10.99 × 11 = **$120.89 / year**.
- **UI:** Show the yearly price and a “1 month free” badge (and optionally “Save $X” where X is one month’s price). Toggle updates prices and “Billed monthly” / “Billed yearly” labels.

### 2.3 Currency and rounding (important)

- **Currency:** All prices are **USD**.
- **Stripe uses minor units (cents).** When creating Stripe Prices, use amounts in cents:
  - **Starter yearly:** **6589** cents ($65.89).
  - **Pro yearly:** **12089** cents ($120.89).
  - Starter monthly: 599 cents ($5.99); Pro monthly: 1099 cents ($10.99).
- The “.89” yearly totals are correct (11 × .99 = .89 in the ones place). Do not “round” them to .90 or .00 unless the business explicitly changes the rule.
- **If you change monthly prices later:** Recompute yearly as `monthly_price × 11`, store the result in cents, and keep Stripe Prices and any config/env in sync. Yearly must remain consistent with this formula.

This prevents confusion when creating or updating Stripe Prices in the Dashboard or via API.

### 2.4 Stripe yearly price (correct definition)

- Yearly prices are **recurring** prices with **interval = year** (not month with interval_count).
- **Amount:** Set the price amount in **cents** as above (6589 for Starter yearly, 12089 for Pro yearly). One charge per year.
- **Do not use** `interval_count: 12` or a monthly price repeated 12 times; use a single charge per year with the 11-month total.
- **Config/env:** Store four Price IDs (Starter monthly, Starter yearly, Pro monthly, Pro yearly) and a mapping from `stripe_price_id` → tier and interval for display and enforcement.

---

## 3. Data model (subscriptions table)

### 3.1 Schema

**`users` table (add):**

| Column                | Type   | Constraints       | Notes                                   |
|-----------------------|--------|-------------------|-----------------------------------------|
| `stripe_customer_id`  | string | nullable, unique  | Set on first successful checkout / webhook |

**`subscriptions` table (new):**

| Column                    | Type     | Constraints   | Notes |
|---------------------------|----------|---------------|-------|
| `user_id`                 | bigint   | FK, not null  | |
| `stripe_subscription_id`  | string   | unique, not null | |
| `stripe_price_id`        | string   | not null      | Which price (monthly/yearly, starter/pro) |
| `status`                  | string   | not null      | Stripe status verbatim |
| `current_period_start`   | datetime | nullable      | Start of current Stripe billing period (for quota window) |
| `current_period_end`     | datetime | nullable      | End of current Stripe billing period |
| `cancel_at_period_end`   | boolean  | default false | |
| `created_at` / `updated_at` | datetime | | |

**One active subscription per user (invariant):**

- A user may have **multiple historical** subscriptions (e.g. after cancel and resubscribe), but **only one** subscription may have `status` in **`active`** or **`trialing`** at any time.
- **Enforcement (plan-level; later in DB):** Enforce via a **partial unique index** on `(user_id)` where `status IN ('active', 'trialing')`, so at most one row per user can be active or trialing.
- **When a new subscription becomes active or trialing:** Any **previous** subscription for that user with status `active` or `trialing` must be updated: mark as **canceled** (or equivalent) or **archived** so that only the new subscription is active/trialing. Webhook handlers must apply this whenever they set a subscription to active/trialing.

### 3.2 Pro and paid logic

- **`User#pro?` (or equivalent “paid” concept):**  
  **`true`** only when the user has a subscription with `status` in **`active`** or **`trialing`**.  
  **`false`** for all other statuses: `past_due`, `unpaid`, `incomplete`, `incomplete_expired`, `paused`, `canceled`, or when there is no such subscription.

- **Plan tier derivation:**
  - **Free:** No subscription with `status` in `[active, trialing]`.
  - **Starter:** Active/trialing subscription whose `stripe_price_id` maps to Starter (monthly or yearly).
  - **Pro:** Active/trialing subscription whose `stripe_price_id` maps to Pro (monthly or yearly).

- **PDF branding:** Existing logic: `show_powered_by: !current_user.pro?`. Free → “Powered by …”; Starter and Pro → no branding.

---

## 4. Stripe integration (webhook-driven source of truth)

### 4.1 Checkout

- **Mode:** Stripe Checkout, **subscription**.
- **Price IDs:** Four — Starter monthly, Starter yearly ($65.89/yr = 6589 cents), Pro monthly, Pro yearly ($120.89/yr = 12089 cents). Chosen from the user’s selection (tier + Monthly/Yearly toggle).
- **Customer:** Use `customer_email: current_user.email` if `stripe_customer_id` is blank; otherwise `customer: user.stripe_customer_id`.
- **Success/cancel URLs:** e.g. `/settings/billing?checkout=success` and `/pricing?checkout=cancel`. Success URL must **not** grant access; only webhooks do.

### 4.2 Customer Portal

- Use Stripe Customer Portal for: update payment method, view invoices, cancel subscription, (optionally) switch plan.  
- “Manage subscription” in Settings → Billing creates a Portal Session and redirects to Stripe.

### 4.3 Provisioning paths (both must work)

- A local **subscription** record may be created or updated by **either**:
  - **`checkout.session.completed`**, or  
  - **`customer.subscription.created`** / **`customer.subscription.updated`**
- **Reason:** Stripe does not guarantee the order of these events. The system must tolerate e.g. `customer.subscription.updated` arriving **before** `checkout.session.completed`.
- **Behavior:** Whichever event arrives first creates or updates the local subscription row (from Stripe data). Subsequent events reconcile and overwrite as needed. No assumption about event order.

### 4.4 Webhook syncing: always from Stripe + timestamp guard

- **Source of truth:** Local subscription state is **never inferred**. It is **always derived from** the Stripe subscription object (from the event payload or by fetching from the Stripe API when the event only contains IDs).
- **On any webhook that references a subscription ID** (`checkout.session.completed`, `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`):
  - **Sync** the local subscription row from the **Stripe subscription object** (all relevant fields: `stripe_subscription_id`, `stripe_price_id`, `status`, `current_period_start`, `current_period_end`, `cancel_at_period_end`, etc.).
  - **Timestamp guard:** Use the Stripe event’s **created** timestamp. Before applying the update, compare it to the **last processed event timestamp** stored for that subscription (e.g. in a `webhook_events` table or a `last_synced_at` / `last_event_created` on the subscription). **Ignore** events that are **older** than the last processed timestamp for that subscription. This avoids overwriting newer state with stale retries or out-of-order delivery.
  - **Apply overwrite-style sync:** “Latest valid event wins.” When the event is not ignored, overwrite local subscription fields with the values from Stripe.

### 4.5 Webhook events and responsibilities

| Event | Responsibility |
|-------|----------------|
| **`checkout.session.completed`** | If `stripe_customer_id` missing on user, set it from `session.customer`. Create or update subscription row from the Stripe subscription (session.subscription → fetch from API if needed). Sync all subscription fields from Stripe. Apply timestamp guard. Ensure only one active/trialing per user. |
| **`customer.subscription.created`** | Create or update local subscription from Stripe subscription object. Sync all fields. Apply timestamp guard. Ensure only one active/trialing per user. |
| **`customer.subscription.updated`** | Update local subscription from Stripe subscription object. Sync status, current_period_start, current_period_end, cancel_at_period_end, stripe_price_id. Apply timestamp guard. Ensure only one active/trialing per user. |
| **`customer.subscription.deleted`** | Mark subscription ended (e.g. set status to `canceled` or archive). Apply timestamp guard. User becomes Free. |
| **`invoice.payment_succeeded`** (or `invoice.paid`) | Optional: confirm renewal; update current_period_start / current_period_end from invoice if needed. |
| **`invoice.payment_failed`** | No direct update; Stripe will update subscription status. Subsequent `customer.subscription.updated` will sync; user loses Pro until payment succeeds. |

### 4.6 Webhook security and reliability

- **Signature verification:** Use Stripe’s `construct_event` (or equivalent) with the **raw request body** and webhook signing secret. Reject if verification fails.
- **CSRF:** Webhook endpoint must be CSRF-exempt.
- **Idempotency:** Persist processed Stripe event IDs (e.g. `webhook_events` table with unique `stripe_event_id`). Before processing, check if the event was already processed; if so, return 200 and skip.
- **Retries and order:** Combined with the timestamp guard, “latest valid event wins” ensures that out-of-order or duplicate events do not corrupt state.

---

## 5. Plan limits enforcement (Free vs Starter vs Pro)

### 5.1 Config source

- Single source of truth for limits (e.g. **YAML** `config/plans.yml` or **plans** table). Structure must support:
  - **Free:** clients: 4 (total), proposals: 4 (per month), invoices: 4 (per month), templates: 4 (total).
  - **Starter:** clients: 30 (total), proposals: 50 (per month), invoices: 50 (per month), templates: 10 (total).
  - **Pro:** unlimited for all (no cap checks).

### 5.2 Where to enforce

- **Actions:** `new` and `create` for clients, proposals, invoices, and proposal templates.
- **Logic:**
  - **Clients and templates:** Compare **total** count to plan limit (e.g. `user.clients.count` vs limit for current plan).
  - **Proposals and invoices:** Compare **monthly** count (creates only; see §1.3) to plan limit:
    - **Paid users:** Count **created** within the subscription’s **Stripe billing period** (`current_period_start` → `current_period_end`).
    - **Free users:** Count **created** within the **current calendar month (UTC)**.
  - “Unlimited” means no check for that resource.

### 5.3 When quota is exceeded

- **Block** the action and **redirect** to **`/pricing`**.
- **Flash:** Contextual message, e.g. “You’ve reached your monthly proposal limit” or “You’ve reached your monthly invoice limit” or “You’ve reached your limit for clients” / “… for templates” as appropriate. Include the recommended paid tier (e.g. “Upgrade to Starter or Pro to add more”).
- **Pricing page:** Show the same Monthly/Yearly toggle and three plan cards; **highlight the appropriate paid tier** and **keep the toggle state** (e.g. if they had Yearly selected, keep Yearly). Optionally pass a query param (e.g. `?limit=invoices`) to scroll to or emphasize the right tier.

---

## 6. UX / UI requirements

### 6.1 Design principles

- On-brand: black/white theme, bold, modern, clean (consistent with existing landing).
- Clear visual hierarchy; scan-friendly plan cards.
- No walls of checkmarks; concise bullets per plan.

### 6.2 Monthly / Yearly toggle

- **Places:** Landing page pricing section (public); dedicated **`/pricing`** page (public).
- **Behavior:** Toggle updates visible prices, “Billed monthly” / “Billed yearly” labels, and CTA copy. Paid tier CTAs use **“Pay yearly — 1 month free”** when yearly is selected (not “Start free month (yearly)”). CTAs create a Checkout Session with the correct Stripe Price ID (monthly vs yearly for the chosen tier).

### 6.3 Plan cards (3)

- **Free:** Limits (4 clients total, 4 proposals/month, 4 invoices/month, 4 templates total), PDF “Powered by …”. CTA: “Get started.”
- **Starter:** $5.99/mo or $65.89/yr (“1 month free”), limits (30 clients, 50 proposals/month, 50 invoices/month, 10 templates), no PDF branding. CTA: “Upgrade” (monthly) / “Pay yearly — 1 month free” (yearly).
- **Pro:** $10.99/mo or $120.89/yr (“1 month free”), unlimited, no PDF branding. CTA: same pattern.
- **“Most popular”:** Mark **Starter** as “Most popular”. Middle tier is the natural upgrade from Free; Pro is for power users who self-select.

### 6.4 Trust and copy

- “Cancel anytime.”
- “Secure checkout by Stripe.”
- FAQ accordion: 2–4 items (e.g. “Can I change plans later?”, “What happens when I hit my limit?”, “How does annual billing work?”, “How do I cancel?”).
- Annual billing: Make clear it is a **discount** (pay for 11 months, get 12); user is **billed immediately** for the yearly amount — not a free trial.

### 6.5 Consistency when hitting limits

- When a user hits a limit → redirect to **`/pricing`** with contextual flash; **keep the same toggle and three tiers**. Optionally use `?limit=…` to highlight the right tier.

### 6.6 Settings → Billing (authenticated)

- **Current plan:** Free | Starter | Pro.
- **Usage counters:** For Free/Starter show e.g. “3/4 clients”, “2/4 proposals this month”, “1/4 invoices this month”, “0/4 templates” (or the correct limits and “this month” for flow quotas). For Pro show “Unlimited” where applicable.
- **Next billing date:** If subscribed, show `current_period_end` (“Renews on …”). If `cancel_at_period_end`, show “Cancels on [date]”.
- **Button:** “Manage subscription” → Stripe Customer Portal (paid); “Upgrade” / “View plans” → `/pricing` (Free).
- **Upgrade nudge:** If Free and **near** limit (e.g. 3/4 clients or 3/4 proposals this month), show a tasteful nudge: “You’re close to your plan limit. Upgrade to add more.”

### 6.7 Post-checkout and transient states

- **Checkout success but webhook delayed:** Do **not** grant entitlement from the success URL. In Settings → Billing, show “Activating your plan…” with a short note that it may take a moment. When the webhook is processed, show the correct plan and usage.
- **Payment fails / subscription past_due:** User loses Pro. Show upgrade prompt; plan “Free” (or “Past due”); “Update payment method” (Portal) or “Upgrade again.”
- **cancel_at_period_end:** User remains Pro until `current_period_end`. Show “Your plan will cancel on [date]. You can reactivate in the Customer Portal.”

---

## 7. Purchase flow and event/state logic

### 7.1 Sequence (with Monthly/Yearly)

```mermaid
sequenceDiagram
  participant User
  participant App
  participant Stripe

  User->>App: Open /pricing or landing pricing
  App->>User: Show 3 plans + Monthly/Yearly toggle

  User->>User: Select tier (Starter/Pro) + interval (Monthly/Yearly)
  User->>App: Click Upgrade / Pay yearly — 1 month free
  App->>App: Resolve Stripe Price ID from tier + interval
  App->>Stripe: Create Checkout Session (subscription, price_id)
  Stripe->>User: Redirect to Stripe Checkout
  User->>Stripe: Complete payment (billed immediately)

  Stripe->>App: Webhook checkout.session.completed OR subscription.created/updated
  App->>App: Set stripe_customer_id; create/update subscription from Stripe (timestamp guard)
  Stripe->>App: (Other webhook if order differs) Reconcile subscription row

  Stripe->>User: Redirect to success_url (e.g. /settings/billing)
  App->>User: Show plan or "Activating…" if webhook not yet processed

  User->>App: Settings > Manage subscription
  App->>Stripe: Create Portal Session
  Stripe->>User: Manage/cancel/update in Stripe
  Stripe->>App: Webhook subscription.updated / deleted
  App->>App: Update subscription row; pro? derived from status
```

### 7.2 State summary

| State | pro? | Shown in Billing | Notes |
|-------|------|------------------|-------|
| No subscription | false | Free, usage (totals + monthly) | |
| Subscription active/trialing | true | Starter or Pro, usage, next billing date | PDF branding off |
| Checkout success, webhook not yet received | false (until webhook) | “Activating…” | Do not trust success URL |
| past_due / unpaid / etc. | false | Free (or “Past due”) + CTA to Portal | |
| cancel_at_period_end true | true until period end | “Cancels on [date]” | Still Pro until current_period_end |
| subscription.deleted | false | Free | |

---

## 8. Limits and webhook reference tables

### 8.1 Plan limits (locked)

| Tier    | Clients   | Proposals   | Invoices   | Templates |
|---------|-----------|-------------|------------|-----------|
| Free    | 4 (total) | 4 / month   | 4 / month  | 4 (total) |
| Starter | 30 (total) | 50 / month | 50 / month | 10 (total) |
| Pro     | Unlimited | Unlimited   | Unlimited  | Unlimited |

**Monthly window:** Paid = Stripe billing period (current_period_start → current_period_end). Free = calendar month (UTC). Counts reset at the start of each new window.  
**What counts:** Monthly quota = **created** proposals/invoices in the window (not sends, not PDF exports).

### 8.2 Webhook events → actions

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Set user `stripe_customer_id` if missing. Create or update subscription from Stripe subscription object; apply timestamp guard; ensure only one active/trialing per user. |
| `customer.subscription.created` | Create or update subscription from Stripe subscription object; apply timestamp guard; ensure only one active/trialing per user. |
| `customer.subscription.updated` | Overwrite subscription row from Stripe (status, current_period_start, current_period_end, cancel_at_period_end, stripe_price_id); timestamp guard; ensure only one active/trialing per user. |
| `customer.subscription.deleted` | Mark subscription ended; timestamp guard; user becomes Free. |
| `invoice.payment_succeeded` | Optional: update current_period_start/current_period_end for renewal health. |
| `invoice.payment_failed` | No direct update; rely on subsequent subscription.updated. |

**Rule:** Local state is always derived from Stripe; never inferred. Ignore events older than the last processed timestamp for that subscription.

---

## 9. UX wire-outline

### 9.1 Landing page — pricing section

- Nav + hero (existing); scroll or link to **Pricing**.
- **Toggle:** [ Monthly ] [ Yearly ] — default Monthly.
- **Three cards:** Free | Starter (Most popular) | Pro.
- Each card: name, price (updates with toggle), bullets, CTA. Paid yearly CTA: “Pay yearly — 1 month free”.
- Below: “Cancel anytime” · “Secure checkout by Stripe”.
- **FAQ:** Accordion, 2–4 questions; clarify yearly = discount, billed immediately.

### 9.2 Dedicated /pricing page (public)

- Same layout: toggle + 3 cards + trust + FAQ.
- When redirected from “limit reached”: contextual flash; **highlight recommended tier**; **keep Monthly/Yearly toggle state**; optional `?limit=…`.

### 9.3 Settings → Billing (authenticated)

- **Plan:** Free | Starter | Pro.
- **Usage:** Total counts for clients/templates; monthly counts for proposals/invoices (e.g. “2/4 proposals this month”).
- **Next billing date** or “Cancels on [date]”.
- **Actions:** “Manage subscription” or “Upgrade” / “View plans”.
- **Nudge:** If Free and near limit, “You’re close to your plan limit. Upgrade to add more.”
- **“Activating…”:** When success_url was just hit but webhook has not yet updated the subscription.

---

## 10. Implementation phases (with hard stops)

Execution is split into **three phases**. Do not proceed to the next phase until the user confirms the current phase is complete and asks to continue.

---

### Phase 1: Data model, plan config, and limit enforcement

**Goal:** Users have a plan (Free by default); limits are enforced on create; `User#pro?` is driven by subscription state. No Stripe or pricing UI yet.

**Deliverables:**

1. **Database**
   - Migration: add `stripe_customer_id` (string, nullable, unique) to `users`.
   - Migration: create `subscriptions` table with columns per §3.1 (including `current_period_start`, `current_period_end`). Add partial unique index on `(user_id)` where `status IN ('active', 'trialing')` when the DB supports it.
   - Optional: migration for `webhook_events` (e.g. `stripe_event_id` unique, `processed_at`) for idempotency and timestamp guard in Phase 2.

2. **Models**
   - `Subscription` model (belongs_to :user), with status and period accessors.
   - Update `User`: `has_many :subscriptions`; implement `User#pro?` per §3.2 (true only for active or trialing). Add helpers for current plan tier (Free/Starter/Pro) and for limits/usage (total for clients/templates; monthly for proposals/invoices using calendar month UTC for Free and, when present, subscription period for paid).

3. **Plan limits config**
   - Add `config/plans.yml` (or equivalent) with Free, Starter, Pro limits per §5.1. Load in a service or concern so the app can ask “limit for :clients for plan X” and “usage for :proposals this month for user Y.”

4. **Enforcement**
   - In `ClientsController`, `ProposalsController`, `InvoicesController`, `ProposalTemplatesController`: before_action on `new` and `create` that checks whether the user is at limit for that resource type. If at limit, redirect to `/pricing` (route can be a placeholder that renders a simple “Coming soon” or the existing home) with a flash message per §5.3. Ensure the redirect and message work for all four resource types.

5. **Locales**
   - Add flash/string keys for limit-reached messages (e.g. “You’ve reached your limit for clients”, “You’ve reached your monthly proposal limit”) in en and es.

**Verification:** Run the app; sign up; create 4 clients (or 4 proposals, or 4 invoices, or 4 templates) and attempt to create one more. You should be redirected with the appropriate message. `User#pro?` should be false for everyone until Phase 2 adds real subscriptions.

---

**HARD STOP — Phase 1 complete**

Do not continue to Phase 2 until the user has verified Phase 1 and explicitly asks to continue (e.g. “Phase 1 is done, continue to Phase 2”).

---

### Phase 2: Stripe integration and Settings → Billing

**Goal:** Users can upgrade via Stripe Checkout; webhooks keep subscription state in sync; Settings shows plan, usage, and “Manage subscription” (Customer Portal).

**Deliverables:**

1. **Stripe**
   - Add `stripe` gem; configure `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, and the four Price IDs (Starter monthly/yearly, Pro monthly/yearly). Use cents for yearly: 6589 and 12089 (§2.3).
   - Checkout: controller action that creates a Checkout Session (mode: subscription, correct price_id from params or session for tier + interval). Redirect user to Stripe. Success URL and cancel URL per §4.1. Do not grant entitlement on success URL.
   - Webhook endpoint: POST endpoint, CSRF-exempt, raw body for signature verification. Handle events per §4.5; create/update subscription from Stripe object; apply timestamp guard; ensure one active/trialing per user. Store processed event IDs for idempotency.
   - Customer Portal: action that creates a Portal Session and redirects the user to Stripe.

2. **Routes**
   - e.g. `post "checkout/create"` (or `billing/checkout`), `post "webhooks/stripe"`, `get "settings/billing"` or use existing settings show with billing section.

3. **Settings → Billing**
   - In Settings (or dedicated billing view), show: current plan (Free/Starter/Pro), usage counters (totals + “this month” for proposals/invoices), next billing date (or “Cancels on …”), “Manage subscription” button (Portal) for paid users, “Upgrade” / “View plans” for Free. Show “Activating your plan…” when `checkout=success` is present but user has no active/trialing subscription yet.

4. **Locales**
   - Billing section labels and messages (including “Activating your plan…”, “Manage subscription”, “Upgrade”).

**Verification:** Use Stripe test mode; go through Checkout for Starter monthly; confirm webhook creates subscription and user becomes Starter; Settings shows correct plan and usage. Test “Manage subscription” (Portal). Test cancel or payment failure and confirm user goes back to Free and limits apply.

---

**HARD STOP — Phase 2 complete**

Do not continue to Phase 3 until the user has verified Phase 2 and explicitly asks to continue (e.g. “Phase 2 is done, continue to Phase 3”).

---

### Phase 3: Pricing UI (landing + /pricing) and polish

**Goal:** Landing has a pricing section and a dedicated `/pricing` page; both have the Monthly/Yearly toggle and three plan cards; CTAs use “Pay yearly — 1 month free” where applicable; trust copy and FAQ are in place; limit redirects land on /pricing with contextual message and correct toggle/cards.

**Deliverables:**

1. **Routes**
   - `get "pricing", to: "pages#pricing"` (or pricing_controller).

2. **Landing page**
   - In `app/views/pages/home.html.erb`, add or expand a **Pricing** section: Monthly/Yearly toggle, three plan cards (Free, Starter as “Most popular”, Pro), concise bullets, CTAs per §6.3. Match existing theme (black/white, accent, glass cards, typography). Below: “Cancel anytime”, “Secure checkout by Stripe”. Optional: 2–4 item FAQ accordion.

3. **Dedicated /pricing page**
   - New view (e.g. `app/views/pages/pricing.html.erb`) with the same structure: toggle, 3 cards, trust, FAQ. Ensure limit redirects from the app point here with flash and optional `?limit=…`; preserve toggle state and highlight the recommended tier when possible.

4. **CTAs and copy**
   - Free: “Get started” (sign up or go to app). Paid monthly: “Upgrade”. Paid yearly: “Pay yearly — 1 month free”. No “Start free month (yearly)”. Copy in locales (en + es) for pricing, FAQ, and trust lines.

5. **Nav/footer**
   - Link to “Pricing” or “Plans” from landing nav and footer so guests and logged-in users can reach /pricing.

6. **Limit redirect**
   - Ensure all “at limit” redirects go to `/pricing` (not a placeholder). Flash and optional query param work; pricing page shows correct tier emphasis.

**Verification:** View landing and /pricing as guest and as logged-in user; toggle Monthly/Yearly and confirm prices and CTA text; click Upgrade and confirm Checkout uses the correct Price ID. Hit a limit in the app and confirm redirect to /pricing with message and correct plan cards. Check theme consistency and accessibility.

---

**HARD STOP — Phase 3 complete**

Implementation is complete. No further phases unless the user requests changes or additions.

---

## 11. Open questions / decisions locked

**Decisions locked:**

- **Currency:** USD; Stripe amounts in cents. Starter yearly 6589 cents, Pro yearly 12089 cents. If monthly prices change, yearly = monthly × 11, kept consistent in config and Stripe.
- **Monthly usage:** Quota counts **created** proposals/invoices only (not sends, not PDF exports). Future “sends per month” or “exports per month” would be separate quotas.
- **Limits:** Stock (total) = clients, templates. Flow (monthly) = proposals, invoices. Free: 4/4/4/4. Starter: 30/50/50/10. Pro: unlimited.
- **Monthly window:** Paid = Stripe billing period; Free = calendar month UTC. Resets at start of each window.
- **Yearly:** interval = year; amount in cents; copy “Pay yearly — 1 month free”; discount, billed immediately.
- **Data model:** subscriptions table; one active/trialing per user; partial unique index; webhook sync from Stripe + timestamp guard.
- **Enforcement:** At limit → block, redirect /pricing, contextual message, highlight tier, keep toggle.
- **UX:** Three tiers; Starter “Most popular”; idempotency and “Activating…” unchanged.

**Open (minimal):**

- Whether to store last processed event timestamp on the subscription row vs only in webhook_events — recommend subscription row for simple guard checks.
- FAQ exact questions — 2–4 items in content pass.

---

*End of Pricing & Billing Plan v2.*
