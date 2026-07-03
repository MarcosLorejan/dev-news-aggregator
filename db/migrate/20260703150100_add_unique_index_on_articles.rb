class AddUniqueIndexOnArticles < ActiveRecord::Migration[8.1]
  def up
    deduplicate_articles

    add_index :articles, [ :external_id, :source_type ], unique: true unless index_exists?(:articles, [ :external_id, :source_type ])
  end

  def down
    remove_index :articles, column: [ :external_id, :source_type ]
  end

  private

  def deduplicate_articles
    execute <<~SQL.squish
      DELETE FROM articles a
      USING articles b
      WHERE a.id < b.id
        AND a.external_id = b.external_id
        AND a.source_type = b.source_type
        AND a.external_id IS NOT NULL
        AND a.source_type IS NOT NULL
    SQL
  end
end
