class CreatePortfolios < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolios do |t|
      t.string :name
      t.string :path
      t.text :tagline
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
