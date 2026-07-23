class AddIndexOnArticlesScore < ActiveRecord::Migration[8.1]
  def change
    add_index :articles, [ :score, :published_at ],
              name: "index_articles_on_score_and_published_at",
              order: { score: :desc, published_at: :desc }
  end
end
