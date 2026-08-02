class EnablePgTrgmAndArticleSimilarityIndexes < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    add_index :articles, :title, using: :gin, opclass: :gin_trgm_ops, name: "index_articles_on_title_trgm"
    add_index :articles, :description, using: :gin, opclass: :gin_trgm_ops, name: "index_articles_on_description_trgm"
  end
end
