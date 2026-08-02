class AddCanonicalUrlToArticles < ActiveRecord::Migration[8.0]
  def up
    add_column :articles, :canonical_url, :string
    add_index :articles, :canonical_url

    say_with_time "backfill articles.canonical_url" do
      Article.reset_column_information
      Article.find_each do |article|
        canonical = UrlCanonicalizer.canonicalize(article.url)
        article.update_columns(canonical_url: canonical) if canonical.present?
      end
    end
  end

  def down
    remove_index :articles, :canonical_url
    remove_column :articles, :canonical_url
  end
end
