class CreateBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmarks do |t|
      t.references :article, null: false, foreign_key: true
      t.datetime :bookmarked_at

      t.timestamps
    end
  end
end
