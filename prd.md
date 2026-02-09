# PRD — Freelancer Hub

## 0) Purpose
Build a lightweight "Freelancer Command Center" web app for solo freelancers to:
1. Create + send proposals, track status (viewed/accepted)
2. Convert accepted proposals into clients
3. Create invoices with deposits, discounts, and accept payments via Stripe Connect
4. Provide a client portal to view proposals/invoices, pay, and download PDFs

---

## 1) Target Users
**Primary:** Solo freelancers (developers, designers, marketers, consultants) — both tech-savvy and non-technical. Mixed audience requires dead-simple UX.

**Secondary (Post-MVP):** Small agencies (2–5 people)

---

## 2) Core Value Proposition
"Close clients and get paid — fast."
Replace Docs + PDFs + PayPal + emails + spreadsheets with one simple hub.

---

## 3) Business Model

### Payments Architecture (Non-custodial)
- Clients pay freelancers directly via Stripe Connect Standard
- Flow: Client → Freelancer's Stripe → Freelancer's bank
- Platform charges subscription fees only (SaaS)

### Pricing
| Tier | Price | Features |
|------|-------|----------|
| Free | $0 | 1 client, 3 invoices/mo, 1 proposal/mo, basic PDFs, "Powered by" branding, NO portal |
| Pro | $12/mo or $132/yr | Unlimited clients/proposals/invoices, client portal, remove branding, custom logo, manual reminders |
| Business | TBD | Post-MVP: team members, roles, analytics |

### Limit Enforcement
**Hard block:** When free users hit limits, they cannot create more until next month or upgrade. Clear upgrade prompt shown.

---

## 4) MVP Scope

### A) Auth & Accounts
- Email/password auth
- User profile: name, business name, address, logo upload
- **Language preference:** EN or ES (affects entire UI)
- Stripe Connect Standard onboarding (optional, but required for payments)
- Subscription billing for Pro tier (Stripe Billing)

### B) Proposals

**Fields:**
- Client info (name, email, **language: EN/ES**)
- Project title, scope, deliverables (rich text)
- Timeline (start date, end date or duration)
- Pricing: fixed amount OR hourly rate with estimate
- Terms section (simple text)
- **Expiration date** (optional)

**States:** Draft → Sent → Viewed → Accepted → (Converted to Client)

**View Tracking:** Mark as "Viewed" on page load

**Share Link:**
- URL format: `app.com/p/{random_token}` (no info leakage)
- Signed token, expires when proposal expires (if set)

**Acceptance:**
- Full e-signature: typed name + timestamp + IP address captured
- On accept: Auto-create Client record (if new)

**Templates:**
- Freelancers can save proposals as custom templates for reuse
- Templates are per-user

### C) Clients

**Fields:**
- Contact info (name, email, phone, company)
- **Language preference:** EN or ES (affects emails, portal, PDFs sent to them)
- List of proposals
- List of invoices
- Portal access (magic link)

**Relationships:**
- Client belongs_to User
- Client has_many Proposals, Invoices

### D) Invoices

**Fields:**
- Line items (description, quantity, rate, amount)
- **Discount:** Single invoice-level field (% or fixed amount)
- **Tax notes:** Text field only (no calculation)
- **Deposit:** Optional % (e.g., 50%). System calculates deposit amount.
- Due date
- Notes (text)

**States:** Draft → Sent → Partially Paid → Paid → Overdue

**Payments:**
- Invoice has_many Payments
- When deposit set: Two Stripe Checkout Sessions created
  - Deposit session (active immediately)
  - Final payment session (unlocks after deposit paid)
- If freelancer hasn't connected Stripe: invoice can be sent (PDF only, no payment button)

**PDF Generation:** Grover (HTML → PDF via headless Chrome)
- Free tier: "Powered by [AppName]" with link
- Pro tier: Remove branding, add custom logo

**Emails:**
- From: no-reply@[platform]
- Body includes freelancer's email for contact
- Provider: SendGrid

### E) Client Portal

**Authentication:**
- Magic link via email
- Session: 24 hours
- URL: `app.com/portal/{token}`

**Capabilities:**
- View accepted proposals
- View all invoices + payment status
- **Accept proposals** (with e-signature)
- **Pay invoices** (redirects to Stripe Checkout)
- Download PDFs / receipts

**Access:**
- Free tier: NO client portal (direct links only)
- Pro tier: Full portal access

### F) Notifications (MVP)
- Proposal sent email
- Proposal viewed (notify freelancer)
- Proposal accepted (notify freelancer)
- Invoice sent email
- Invoice paid (notify freelancer)
- **Reminders: Manual only** (freelancer clicks "Send reminder" button)

### G) Stripe Integration

**Connect Standard:**
- Each freelancer connects their own Stripe account
- Store `stripe_account_id` on User
- Create Checkout Sessions on connected account using `stripe_account` header

**Webhooks:**
- `payment_intent.succeeded` → Mark payment as complete
- `charge.refunded` → Update payment/invoice status
- `charge.dispute.created` → Flag for freelancer

**Platform Billing:**
- Separate from connected accounts
- Platform's own Stripe account handles Pro subscriptions

### H) Internationalization (MVP)

**Languages:** English, Spanish

**Scope:**
- UI: Fully translated (freelancer chooses in settings)
- Client-facing (emails, PDFs, portal): Uses client's language preference
- Data model: `users.language`, `clients.language`

---

## 5) Data Model

```
users
  - id, email, password_digest
  - name, business_name, address, logo (ActiveStorage)
  - language (en/es)
  - stripe_account_id (nullable)
  - subscription_status, subscription_plan
  - created_at, updated_at

clients
  - id, user_id
  - name, email, phone, company
  - language (en/es)
  - portal_token, portal_token_expires_at
  - created_at, updated_at

proposals
  - id, user_id, client_id (nullable until sent)
  - title, scope, deliverables, timeline_start, timeline_end
  - pricing_type (fixed/hourly), amount, hourly_rate, estimated_hours
  - terms
  - expires_at (nullable)
  - status (draft/sent/viewed/accepted)
  - share_token
  - signature_name, signature_ip, signature_at
  - created_at, updated_at

proposal_templates
  - id, user_id
  - name, content (JSON blob of proposal fields)
  - created_at, updated_at

invoices
  - id, user_id, client_id, proposal_id (nullable)
  - invoice_number
  - discount_type (percent/fixed), discount_value
  - tax_notes
  - deposit_percent (nullable)
  - due_date
  - notes
  - status (draft/sent/partially_paid/paid/overdue)
  - share_token
  - created_at, updated_at

invoice_items
  - id, invoice_id
  - description, quantity, rate, amount
  - created_at, updated_at

payments
  - id, invoice_id
  - payment_type (deposit/final/full)
  - amount
  - stripe_checkout_session_id
  - stripe_payment_intent_id
  - status (pending/completed/refunded)
  - paid_at
  - created_at, updated_at

subscriptions
  - id, user_id
  - stripe_subscription_id
  - plan (free/pro)
  - status (active/canceled/past_due)
  - current_period_end
  - created_at, updated_at
```

---

## 6) Technical Stack

| Component | Choice |
|-----------|--------|
| Framework | Rails 7 |
| Database | PostgreSQL |
| CSS | Tailwind |
| JS | Hotwire (Turbo + Stimulus) |
| Background Jobs | Sidekiq + Redis |
| File Storage | ActiveStorage (S3 or local) |
| PDF | Grover (headless Chrome) |
| Email | SendGrid |
| Payments | Stripe Connect Standard + Stripe Billing |
| Hosting | Render |
| I18n | Rails I18n (en.yml, es.yml) |

---

## 7) Security

- **Proposal/Invoice links:** Signed random tokens, no user info in URL
- **Portal auth:** Magic link with 24hr expiry, new token each request
- **Tenant isolation:** All queries scoped by `user_id` or `client.user_id`
- **Rate limiting:** Rack::Attack for login, magic link requests
- **HTTPS:** Required everywhere

---

## 8) UX Principles

- New user flow: Signup → "Create your first proposal"
- Minimal sidebar: Dashboard, Proposals, Clients, Invoices, Settings
- Dashboard shows: Outstanding invoices, proposals awaiting response, revenue this month
- One-click flow: Proposal → Client → Invoice

---

## 9) Key Flows

### Flow 1: New Client via Proposal
1. Freelancer creates proposal
2. Sends to client email
3. Client views (marked as Viewed)
4. Client accepts (e-signature)
5. Client record created automatically
6. Freelancer creates invoice for client
7. Sends invoice
8. Client pays via portal or direct link
9. Webhook updates invoice to Paid

### Flow 2: Existing Client, Direct Invoice
1. Freelancer creates invoice for existing client
2. Sends invoice
3. Client pays
4. Done

### Flow 3: Deposit Invoice
1. Freelancer creates invoice with 50% deposit
2. System creates two Checkout Sessions
3. Client pays deposit (first session)
4. Invoice status: Partially Paid
5. Final session becomes active
6. Client pays remainder
7. Invoice status: Paid

---

## 10) Explicitly Out of Scope (MVP)

- Chat/messaging
- Time tracking
- Calendar scheduling
- Kanban/project management
- Projects entity (invoices link to clients directly)
- Accounting/taxes calculations
- Multi-currency
- Multi-user teams/roles
- Auto reminders (manual only)
- Complex legal doc generator

---

## 11) Metrics (MVP Minimal)

Per user:
- Proposals sent, accepted rate
- Invoices sent, paid rate
- Time-to-pay average

Platform:
- MRR, churn

---

## 12) Launch Checklist

- [ ] Landing page (bilingual EN/ES)
- [ ] Stripe Connect onboarding flow
- [ ] Stripe Billing for Pro tier
- [ ] Email templates (EN + ES)
- [ ] PDF templates (proposal, invoice, receipt)
- [ ] Client portal
- [ ] Basic analytics dashboard

---

## Appendix: Interview Decisions Summary

| # | Category | Decision |
|---|----------|----------|
| 1 | Target | Mixed audience (tech + non-tech) |
| 2 | Language | Bilingual EN/ES from MVP |
| 3 | Client language | Per-client setting |
| 4 | App name | TBD (placeholder) |
| 5 | Pro price | $12/month |
| 6 | Annual | $132/year (1 month free) |
| 7 | Limits | Hard block |
| 8 | Acceptance | Full e-signature (name + timestamp + IP) |
| 9 | Proposal expiry | Optional |
| 10 | Templates | Custom templates allowed |
| 11 | View tracking | Page load = viewed |
| 12 | Deposits | Yes, percentage-based |
| 13 | Deposit links | Two separate (final unlocks after deposit) |
| 14 | Discounts | Invoice-level (% or fixed) |
| 15 | Taxes | Text note only |
| 16 | Late fees | No |
| 17 | Payment tracking | Multiple payments per invoice |
| 18 | Payment method | Stripe Checkout Sessions |
| 19 | Refunds | Via Stripe dashboard |
| 20 | No Stripe | Allow invoice send (PDF only) |
| 21 | Portal auth | Magic link (24hr) |
| 22 | Portal scope | View + pay + accept |
| 23 | Email | SendGrid |
| 24 | PDF | Grover |
| 25 | Hosting | Render |
| 26 | URLs | Random token only |
| 27 | Reply-to | No-reply (email in body) |
| 28 | Projects | No (direct client link) |
| 29 | Conversion | Proposal → Client → Invoice (manual) |
| 30 | Branding | "Powered by" + link (free tier) |
| 31 | Deferred | Auto reminders |
