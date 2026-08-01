class AddLowSignalToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :low_signal, :boolean, null: false, default: false
    add_index :articles, :low_signal
  end
end
