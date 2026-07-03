class CreateFetchRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :fetch_runs do |t|
      t.string :source_key, null: false
      t.string :status, null: false
      t.integer :articles_count, null: false, default: 0
      t.decimal :duration_seconds, precision: 8, scale: 2
      t.string :error_class
      t.text :error_message
      t.datetime :finished_at, null: false

      t.timestamps
    end

    add_index :fetch_runs, :source_key, unique: true
    add_index :fetch_runs, :status
    add_index :fetch_runs, :finished_at
  end
end
