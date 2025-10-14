class CreateDismissedArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :dismissed_articles do |t|
      t.references :article, null: false, foreign_key: true
      t.datetime :dismissed_at, null: false
      t.boolean :permanent, default: false

      t.timestamps
    end

    add_index :dismissed_articles, :dismissed_at
    add_index :dismissed_articles, :permanent
  end
end
