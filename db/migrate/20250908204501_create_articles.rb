class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :url
      t.datetime :published_at
      t.text :description
      t.string :external_id
      t.string :source_type
      t.integer :score
      t.integer :comment_count

      t.timestamps
    end
  end
end
