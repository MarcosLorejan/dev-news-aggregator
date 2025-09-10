class CreateReadArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :read_articles do |t|
      t.references :article, null: false, foreign_key: true
      t.datetime :read_at

      t.timestamps
    end
  end
end
