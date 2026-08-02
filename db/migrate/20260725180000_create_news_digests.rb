class CreateNewsDigests < ActiveRecord::Migration[8.0]
  def change
    create_table :news_digests do |t|
      t.string :period, null: false
      t.datetime :window_start, null: false
      t.datetime :window_end, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end

    add_index :news_digests, [ :period, :window_start, :window_end ]
  end
end
