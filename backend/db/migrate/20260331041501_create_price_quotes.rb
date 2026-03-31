class CreatePriceQuotes < ActiveRecord::Migration[7.0]
  def change
    create_table :price_quotes do |t|
      t.string   :base,      null: false
      t.string   :quote,     null: false
      t.decimal  :buy_rate,  null: false, precision: 20, scale: 8
      t.decimal  :sell_rate, null: false, precision: 20, scale: 8
      t.datetime :fetched_at, null: false
      t.timestamps null: false
    end

    add_index :price_quotes, [:base, :quote]
    add_index :price_quotes, :fetched_at
  end
end
