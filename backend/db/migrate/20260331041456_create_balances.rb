class CreateBalances < ActiveRecord::Migration[7.0]
  def change
    create_table :balances do |t|
      t.references :user,     null: false, foreign_key: true
      t.string     :currency, null: false
      t.decimal    :amount,   null: false, default: "0", precision: 20, scale: 8
      t.integer    :lock_version, null: false, default: 0
      t.timestamps null: false
    end

    add_index :balances, [:user_id, :currency], unique: true
    add_check_constraint :balances, "amount >= 0", name: "chk_balances_non_negative"
  end
end
