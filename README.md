# Freelancer Hub

A lightweight web app for solo freelancers to manage proposals, invoices, and client relationships.

## Tech Stack

- **Framework:** Rails 7.2
- **Database:** PostgreSQL
- **CSS:** Tailwind CSS
- **JavaScript:** Hotwire (Turbo + Stimulus)
- **Auth:** Devise
- **Testing:** RSpec + factory_bot

## Prerequisites

- Ruby 3.1+ (check `.ruby-version`)
- PostgreSQL installed and running
- Node.js (for Tailwind CSS compilation)

## Setup

1. **Clone and install dependencies:**
   ```bash
   bundle install
   ```

2. **Create and migrate database:**
   ```bash
   bin/rails db:create db:migrate
   ```

3. **Seed demo user (development only):**
   ```bash
   bin/rails db:seed
   ```

4. **Start the development server:**
   ```bash
   bin/dev
   ```

5. **Open the app:**
   Visit [http://localhost:3000](http://localhost:3000)

## Demo Login

After running `db:seed`, you can log in with:
- **Email:** demo@example.com
- **Password:** password123

## Development

### Running the server
```bash
bin/dev  # Starts Rails + Tailwind watcher via foreman
```

### Running tests
```bash
bundle exec rspec
```

### Tailwind CSS
Tailwind is automatically compiled in development via `bin/dev`. For production builds:
```bash
bin/rails tailwindcss:build
```

## Features (Milestone 1)

- [x] User authentication (sign up, sign in, sign out)
- [x] Bilingual UI (English/Spanish)
- [x] Dashboard with sidebar navigation
- [x] Settings page (profile, language, logo upload)
- [x] Placeholder pages for Proposals, Clients, Invoices

## Project Structure

```
app/
  controllers/
    dashboard_controller.rb    # Main dashboard
    settings_controller.rb     # User settings
    proposals_controller.rb    # Placeholder
    clients_controller.rb      # Placeholder
    invoices_controller.rb     # Placeholder
  models/
    user.rb                    # User with language enum + logo attachment
  views/
    layouts/
      _authenticated.html.erb  # Sidebar layout for logged-in users
      _guest.html.erb          # Centered layout for auth pages
    dashboard/
    settings/
    devise/                    # Customized auth views
config/
  locales/
    en.yml                     # English translations
    es.yml                     # Spanish translations
```

## Upcoming Milestones

- **M2:** Clients CRUD
- **M3:** Proposals (create, send, view tracking)
- **M4:** Proposal acceptance + templates
- **M5:** Invoices + PDF generation
- **M6:** Stripe Connect + payments
- **M7:** Client portal
- **M8:** Subscriptions + plan gating
