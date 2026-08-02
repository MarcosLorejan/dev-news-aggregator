class CreateKeywordFilters < ActiveRecord::Migration[8.1]
  def change
    create_table :keyword_filters do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :terms, array: true, null: false, default: []
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :keyword_filters, :slug, unique: true
    add_index :keyword_filters, [ :active, :position ]
  end
end
