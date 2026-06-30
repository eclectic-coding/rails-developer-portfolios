class AddUniqueIndexToPortfoliosPath < ActiveRecord::Migration[8.1]
  def change
    add_index :portfolios, :path, unique: true
  end
end
