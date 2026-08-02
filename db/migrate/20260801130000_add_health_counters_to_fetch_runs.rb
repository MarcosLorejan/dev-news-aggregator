class AddHealthCountersToFetchRuns < ActiveRecord::Migration[8.0]
  def change
    change_table :fetch_runs, bulk: true do |t|
      t.integer :success_count, null: false, default: 0
      t.integer :failure_count, null: false, default: 0
      t.integer :empty_success_count, null: false, default: 0
      t.datetime :last_success_at
      t.datetime :last_failure_at
    end
  end
end
