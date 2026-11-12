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

ActiveRecord::Schema[8.1].define(version: 2026_11_12_213926) do
  create_table "comments", force: :cascade do |t|
    t.integer "decision_id", null: false
    t.integer "passage_id"
    t.integer "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["decision_id", "created_at"], name: "index_comments_on_decision_id_and_created_at"
    t.index ["decision_id"], name: "index_comments_on_decision_id"
    t.index ["passage_id"], name: "index_comments_on_passage_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "decisions", force: :cascade do |t|
    t.integer "term", null: false
    t.string "docket_number", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.date "decided_on"
    t.string "citation"
    t.text "holding"
    t.string "author_code"
    t.string "pdf_url", null: false
    t.integer "status", default: 0, null: false
    t.text "import_error"
    t.datetime "imported_at"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pdf_url"], name: "index_decisions_on_pdf_url", unique: true
    t.index ["slug"], name: "index_decisions_on_slug", unique: true
    t.index ["term", "decided_on"], name: "index_decisions_on_term_and_decided_on"
  end

  create_table "opinions", force: :cascade do |t|
    t.integer "decision_id", null: false
    t.integer "kind", default: 0, null: false
    t.string "label", null: false
    t.string "author"
    t.integer "position", null: false
    t.text "body_html", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["decision_id", "position"], name: "index_opinions_on_decision_id_and_position", unique: true
    t.index ["decision_id"], name: "index_opinions_on_decision_id"
  end

  create_table "passages", force: :cascade do |t|
    t.integer "decision_id", null: false
    t.integer "opinion_id"
    t.string "key", null: false
    t.integer "position", null: false
    t.text "text", null: false
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["decision_id", "key"], name: "index_passages_on_decision_id_and_key", unique: true
    t.index ["decision_id"], name: "index_passages_on_decision_id"
    t.index ["opinion_id"], name: "index_passages_on_opinion_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "comments", "decisions"
  add_foreign_key "comments", "passages"
  add_foreign_key "comments", "users"
  add_foreign_key "opinions", "decisions"
  add_foreign_key "passages", "decisions"
  add_foreign_key "passages", "opinions", on_delete: :nullify
  add_foreign_key "sessions", "users"
end
