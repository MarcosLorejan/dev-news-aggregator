class AddSummaryToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :summary, :text
    add_column :articles, :summary_provider, :string
    add_column :articles, :summarized_at, :datetime
  end
end
