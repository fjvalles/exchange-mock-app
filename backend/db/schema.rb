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

ActiveRecord::Schema[7.0].define(version: 2026_03_31_041501) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "balances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "currency", null: false
    t.decimal "amount", precision: 20, scale: 8, default: "0.0", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "currency"], name: "index_balances_on_user_id_and_currency", unique: true
    t.index ["user_id"], name: "index_balances_on_user_id"
    t.check_constraint "amount >= 0::numeric", name: "chk_balances_non_negative"
  end

  create_table "exchanges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "from_currency", null: false
    t.string "to_currency", null: false
    t.decimal "from_amount", precision: 20, scale: 8, null: false
    t.decimal "to_amount", precision: 20, scale: 8
    t.decimal "locked_rate", precision: 20, scale: 8, null: false
    t.string "status", default: "pending", null: false
    t.string "idempotency_key"
    t.text "failure_reason"
    t.datetime "executed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_exchanges_on_created_at"
    t.index ["idempotency_key"], name: "idx_exchanges_idempotency_key", unique: true, where: "(idempotency_key IS NOT NULL)"
    t.index ["user_id", "created_at"], name: "idx_exchanges_pending", where: "((status)::text = 'pending'::text)"
    t.index ["user_id", "status"], name: "index_exchanges_on_user_id_and_status"
    t.index ["user_id"], name: "index_exchanges_on_user_id"
    t.check_constraint "from_amount > 0::numeric", name: "chk_exchanges_positive_amount"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'completed'::character varying, 'rejected'::character varying]::text[])", name: "chk_exchanges_valid_status"
  end

  create_table "price_quotes", force: :cascade do |t|
    t.string "base", null: false
    t.string "quote", null: false
    t.decimal "buy_rate", precision: 20, scale: 8, null: false
    t.decimal "sell_rate", precision: 20, scale: 8, null: false
    t.datetime "fetched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base", "quote"], name: "index_price_quotes_on_base_and_quote"
    t.index ["fetched_at"], name: "index_price_quotes_on_fetched_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "api_token", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "balances", "users"
  add_foreign_key "exchanges", "users"
end
