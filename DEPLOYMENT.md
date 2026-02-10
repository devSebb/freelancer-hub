# Deploying Freelancer Hub to Render

This guide walks you through deploying the app to [Render](https://render.com) using Docker and a managed PostgreSQL database.

---

## Prerequisites

- A [Render](https://render.com) account
- This repo pushed to GitHub (or GitLab)
- Your production `config/master.key` value (from your machine; do **not** commit it)

---

## Step 1: Create a PostgreSQL database on Render

1. In the [Render Dashboard](https://dashboard.render.com), click **New +** → **PostgreSQL**.
2. Choose a name (e.g. `freelancer-hub-db`), region, and plan.
3. Click **Create Database**.
4. Wait until the DB is **Available**. Open it and copy the **Internal Database URL** (use this for the web service; it’s only reachable from other Render services).

Keep this URL for Step 3. Render will also show an **External Database URL** if you need to connect from outside Render.

---

## Step 2: Create a Web Service (Docker)

1. In the Dashboard, click **New +** → **Web Service**.
2. Connect your GitHub/GitLab account if needed, then select the **freelancer-hub** repository.
3. Configure the service:
   - **Name:** e.g. `freelancer-hub`
   - **Region:** Same as the database (recommended).
   - **Branch:** `main` (or your production branch).
   - **Runtime:** **Docker**.
   - **Dockerfile path:** `Dockerfile` (default).
   - **Instance type:** Choose a plan (e.g. Free or Starter).

Do **not** click **Create Web Service** yet. Add the environment variables first (Step 3).

---

## Step 3: Environment variables

In the Web Service setup, open **Environment** and add these variables.

### Required

| Key | Value | Notes |
|-----|--------|------|
| `RAILS_MASTER_KEY` | *(paste from `config/master.key`)* | Required to decrypt credentials. |
| `DATABASE_URL` | *(Internal Database URL from Step 1)* | From the PostgreSQL service → **Info** → **Internal Database URL**. |

Render can auto-add `DATABASE_URL` if you link the database to the web service (see Step 4).

### Required for correct app URL and email links

| Key | Value | Notes |
|-----|--------|------|
| `APP_HOST` | Your Render URL host, e.g. `freelancer-hub-xxxx.onrender.com` | No `https://`; host only. After first deploy, copy from the service URL. |
| `APP_PROTOCOL` | `https` | Used for links in emails. |

### Required for sending email (e.g. Devise, proposal/invoice mailers)

Set at least one of the following, depending on your provider.

**Option A – SendGrid (recommended on Render)**

- `SMTP_ADDRESS` = `smtp.sendgrid.net`
- `SMTP_PORT` = `587`
- `SMTP_USERNAME` = `apikey`
- `SMTP_PASSWORD` = *(SendGrid API key)*
- `MAILER_SENDER` = e.g. `Freelancer Hub <noreply@yourdomain.com>` (must be a verified sender in SendGrid)

**Option B – Another SMTP provider**

Set the same variables to match your provider (e.g. Mailgun, Postmark). Then set:

- `MAILER_SENDER` = e.g. `Freelancer Hub <noreply@yourdomain.com>`

If you don’t set SMTP variables, the app will still run, but password reset and other emails will not be sent.

### Optional – persistent file storage (S3)

Without S3, uploads (e.g. user logos) use local disk and are **lost on redeploy**. For persistence, use S3:

| Key | Value |
|-----|--------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `AWS_REGION` | e.g. `us-east-1` |
| `AWS_S3_BUCKET` | Your bucket name |

Create a bucket in AWS S3 (or compatible service), allow the IAM user to read/write that bucket, and add the four variables above. The app will use **:amazon** in production when these are set.

---

## Step 4: Link the database to the Web Service

1. In the Web Service form, under **Environment**, click **Link existing resource** (or similar).
2. Select the PostgreSQL database you created in Step 1.
3. Render will add `DATABASE_URL` automatically. You can remove the manual `DATABASE_URL` entry if you added one.

---

## Step 5: Create the Web Service and deploy

1. Click **Create Web Service**.
2. Render will build the Docker image (install gems, Node, Puppeteer, precompile assets) and then start the app.
3. On first boot, the container runs `db:prepare` (create DB if needed, run migrations).
4. Wait until the service shows **Live** and the build log finishes without errors.

---

## Step 6: Set APP_HOST after first deploy

1. Open your Web Service on Render.
2. Copy the URL (e.g. `https://freelancer-hub-xxxx.onrender.com`).
3. Go to **Environment** and set:
   - `APP_HOST` = `freelancer-hub-xxxx.onrender.com` (host only, no `https://`).
4. Save. Render will redeploy; after that, email links (e.g. password reset) will use the correct host.

---

## Step 7: Health check (optional)

Render can use the app’s health endpoint to decide if the app is up:

- **Path:** `/up`
- In the Web Service → **Settings** → **Health Check Path**, set to `/up` if you want Render to use it.

---

## Summary checklist

- [ ] PostgreSQL database created and **Internal Database URL** available.
- [ ] Web Service created with **Docker** runtime.
- [ ] `RAILS_MASTER_KEY` set (from `config/master.key`).
- [ ] `DATABASE_URL` set (or database linked so Render sets it).
- [ ] `APP_HOST` set to your Render host (e.g. `yourapp.onrender.com`).
- [ ] `APP_PROTOCOL` set to `https`.
- [ ] `MAILER_SENDER` set for email “From” address.
- [ ] SMTP variables set if you want to send email (e.g. SendGrid).
- [ ] (Optional) AWS S3 env vars set for persistent uploads.
- [ ] After first deploy, `APP_HOST` updated to the actual Render URL.

---

## Changes made for Render

These were applied so the app runs correctly on Render:

1. **Host authorization** – Production allows `*.onrender.com` and `APP_HOST` so requests aren’t blocked with 403.
2. **Action Mailer** – Production uses `APP_HOST` and `APP_PROTOCOL` for `default_url_options`; Devise mailer sender uses `MAILER_SENDER`.
3. **PDF export (Grover)** – Docker image includes Node.js and Puppeteer (with Chromium) and sets `GROVER_NO_SANDBOX=true` so PDF export works in the container.
4. **Storage** – Production uses S3 when `AWS_ACCESS_KEY_ID` and `AWS_S3_BUCKET` are set; otherwise it uses local disk (ephemeral on Render).
5. **Database** – Uses `DATABASE_URL` from Render when the database is linked.

No code or design changes were made beyond what’s required for deployment and security.
