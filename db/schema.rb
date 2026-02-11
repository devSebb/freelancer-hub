# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_10_101100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "company"
    t.integer "language", default: 0, null: false
    t.string "portal_token"
    t.datetime "portal_token_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portal_token"], name: "index_clients_on_portal_token", unique: true
    t.index ["user_id", "email"], name: "index_clients_on_user_id_and_email", unique: true
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "description", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.decimal "rate", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "position"], name: "index_invoice_items_on_invoice_id_and_position"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "client_id"
    t.bigint "proposal_id"
    t.string "invoice_number", null: false
    t.integer "discount_type", default: 0
    t.decimal "discount_value", precision: 10, scale: 2, default: "0.0"
    t.text "tax_notes"
    t.decimal "deposit_percent", precision: 5, scale: 2
    t.date "due_date"
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.string "share_token", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "payment_methods", default: [], null: false
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number"
    t.index ["proposal_id"], name: "index_invoices_on_proposal_id"
    t.index ["share_token"], name: "index_invoices_on_share_token", unique: true
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["user_id", "invoice_number"], name: "index_invoices_on_user_id_and_invoice_number", unique: true
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "proposal_templates", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.jsonb "content", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_proposal_templates_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_proposal_templates_on_user_id"
  end

  create_table "proposals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "client_id"
    t.string "title", null: false
    t.text "scope"
    t.text "deliverables"
    t.date "timeline_start"
    t.date "timeline_end"
    t.integer "pricing_type", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.decimal "estimated_hours", precision: 10, scale: 2
    t.text "terms"
    t.datetime "expires_at"
    t.integer "status", default: 0, null: false
    t.string "share_token", null: false
    t.string "signature_name"
    t.string "signature_ip"
    t.datetime "signature_at"
    t.datetime "viewed_at"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_proposals_on_client_id"
    t.index ["share_token"], name: "index_proposals_on_share_token", unique: true
    t.index ["status"], name: "index_proposals_on_status"
    t.index ["user_id"], name: "index_proposals_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_subscription_id", null: false
    t.string "stripe_price_id", null: false
    t.string "status", null: false
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_event_created_at"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
    t.index ["user_id"], name: "index_subscriptions_one_active_or_trialing_per_user", unique: true, where: "((status)::text = ANY ((ARRAY['active'::character varying, 'trialing'::character varying])::text[]))"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "business_name"
    t.text "address"
    t.integer "language", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_customer_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "stripe_event_id", null: false
    t.string "event_type", null: false
    t.string "stripe_subscription_id"
    t.datetime "event_created_at", null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_event_id"], name: "index_webhook_events_on_stripe_event_id", unique: true
    t.index ["stripe_subscription_id"], name: "index_webhook_events_on_stripe_subscription_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "clients", "users"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "proposals"
  add_foreign_key "invoices", "users"
  add_foreign_key "proposal_templates", "users"
  add_foreign_key "proposals", "clients"
  add_foreign_key "proposals", "users"
  add_foreign_key "subscriptions", "users"
end
