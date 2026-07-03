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

ActiveRecord::Schema[8.1].define(version: 2026_07_03_150200) do
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
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["external_id", "source_type"], name: "index_articles_on_external_id_and_source_type", unique: true
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["source_type"], name: "index_articles_on_source_type"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "bookmarked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_bookmarks_on_article_id"
  end

  create_table "dismissed_articles", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "dismissed_at", null: false
    t.boolean "permanent", default: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_dismissed_articles_on_article_id"
    t.index ["dismissed_at"], name: "index_dismissed_articles_on_dismissed_at"
    t.index ["permanent"], name: "index_dismissed_articles_on_permanent"
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
    t.index ["article_id"], name: "index_read_articles_on_article_id"
  end

  add_foreign_key "bookmarks", "articles"
  add_foreign_key "dismissed_articles", "articles"
  add_foreign_key "read_articles", "articles"
end
