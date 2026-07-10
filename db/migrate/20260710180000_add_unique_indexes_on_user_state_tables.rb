class AddUniqueIndexesOnUserStateTables < ActiveRecord::Migration[8.1]
  def up
    deduplicate_user_state_rows

    replace_with_unique_index :bookmarks, :article_id, "index_bookmarks_on_article_id"
    replace_with_unique_index :read_articles, :article_id, "index_read_articles_on_article_id"
    replace_with_unique_index :dismissed_articles, :article_id, "index_dismissed_articles_on_article_id"
  end

  def down
    replace_with_non_unique_index :bookmarks, :article_id, "index_bookmarks_on_article_id"
    replace_with_non_unique_index :read_articles, :article_id, "index_read_articles_on_article_id"
    replace_with_non_unique_index :dismissed_articles, :article_id, "index_dismissed_articles_on_article_id"
  end

  private

  def deduplicate_user_state_rows
    %w[bookmarks read_articles dismissed_articles].each do |table|
      execute <<~SQL.squish
        DELETE FROM #{table} a
        USING #{table} b
        WHERE a.id < b.id
          AND a.article_id = b.article_id
      SQL
    end
  end

  def replace_with_unique_index(table, column, index_name)
    remove_index table, name: index_name if index_exists?(table, column, name: index_name)
    add_index table, column, unique: true, name: index_name
  end

  def replace_with_non_unique_index(table, column, index_name)
    remove_index table, name: index_name if index_exists?(table, column, name: index_name)
    add_index table, column, name: index_name
  end
end
