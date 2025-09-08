class CreateNewsSources < ActiveRecord::Migration[8.0]
  def change
    create_table :news_sources do |t|
      t.string :name
      t.string :api_url
      t.string :source_type
      t.boolean :active

      t.timestamps
    end
  end
end
