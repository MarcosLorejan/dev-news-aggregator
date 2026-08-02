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

ActiveRecord::Schema[8.1].define(version: 2026_08_01_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "articles", force: :cascade do |t|
    t.integer "comment_count"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "external_id"
    t.datetime "published_at"
    t.integer "score"
    t.string "source_type"
    t.datetime "summarized_at"
    t.text "summary"
    t.string "summary_provider"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["external_id", "source_type"], name: "index_articles_on_external_id_and_source_type", unique: true
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["score", "published_at"], name: "index_articles_on_score_and_published_at", order: { score: :desc, published_at: :desc }
    t.index ["source_type"], name: "index_articles_on_source_type"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "bookmarked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_bookmarks_on_article_id", unique: true
  end

  create_table "dismissed_articles", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "dismissed_at", null: false
    t.boolean "permanent", default: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_dismissed_articles_on_article_id", unique: true
    t.index ["dismissed_at"], name: "index_dismissed_articles_on_dismissed_at"
    t.index ["permanent"], name: "index_dismissed_articles_on_permanent"
  end

  create_table "fetch_runs", force: :cascade do |t|
    t.integer "articles_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.decimal "duration_seconds", precision: 8, scale: 2
    t.string "error_class"
    t.text "error_message"
    t.datetime "finished_at", null: false
    t.string "source_key", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["finished_at"], name: "index_fetch_runs_on_finished_at"
    t.index ["source_key"], name: "index_fetch_runs_on_source_key", unique: true
    t.index ["status"], name: "index_fetch_runs_on_status"
  end

  create_table "news_sources", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "api_url"
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.index ["source_type", "name"], name: "index_news_sources_on_source_type_and_name", unique: true
  end

  create_table "read_articles", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_read_articles_on_article_id", unique: true
  end

  add_foreign_key "bookmarks", "articles"
  add_foreign_key "dismissed_articles", "articles"
  add_foreign_key "read_articles", "articles"
end
