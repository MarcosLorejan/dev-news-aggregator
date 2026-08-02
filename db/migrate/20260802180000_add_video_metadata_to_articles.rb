class AddVideoMetadataToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :content_type, :string, null: false, default: "article"
    add_column :articles, :duration_seconds, :integer
    add_column :articles, :thumbnail_url, :string
    add_column :articles, :author, :string

    add_index :articles, :content_type
  end
end
