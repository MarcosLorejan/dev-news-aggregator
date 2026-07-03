class AddArticleQueryIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :articles, :published_at unless index_exists?(:articles, :published_at)
    add_index :articles, :source_type unless index_exists?(:articles, :source_type)
  end
end
