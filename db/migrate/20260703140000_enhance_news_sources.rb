class EnhanceNewsSources < ActiveRecord::Migration[8.0]
  def up
    add_column :news_sources, :config, :jsonb, default: {}, null: false
    change_column_default :news_sources, :active, from: nil, to: true

    # Remove duplicate rows before adding the unique index (e.g. legacy placeholder data).
    execute <<~SQL.squish
      DELETE FROM news_sources
      WHERE id NOT IN (
        SELECT MIN(id) FROM news_sources GROUP BY source_type, name
      )
    SQL

    add_index :news_sources, [ :source_type, :name ], unique: true
  end

  def down
    remove_index :news_sources, [ :source_type, :name ]
    remove_column :news_sources, :config
    change_column_default :news_sources, :active, from: true, to: nil
  end
end
