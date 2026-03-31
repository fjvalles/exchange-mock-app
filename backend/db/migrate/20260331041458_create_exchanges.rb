class CreateExchanges < ActiveRecord::Migration[7.0]
  def change
    create_table :exchanges do |t|
      t.references :user,          null: false, foreign_key: true
      t.string     :from_currency, null: false
      t.string     :to_currency,   null: false
      t.decimal    :from_amount,   null: false, precision: 20, scale: 8
      t.decimal    :to_amount,     precision: 20, scale: 8
      t.decimal    :locked_rate,   null: false, precision: 20, scale: 8
      t.string     :status,        null: false, default: "pending"
      t.string     :idempotency_key
      t.text       :failure_reason
      t.datetime   :executed_at
      t.timestamps null: false
    end

    add_index :exchanges, [:user_id, :status]
    add_index :exchanges, :created_at
    add_index :exchanges, :idempotency_key, unique: true,
              where: "idempotency_key IS NOT NULL", name: "idx_exchanges_idempotency_key"
    add_index :exchanges, [:user_id, :created_at],
              where: "status = 'pending'", name: "idx_exchanges_pending"

    add_check_constraint :exchanges, "status IN ('pending', 'completed', 'rejected')",
                         name: "chk_exchanges_valid_status"
    add_check_constraint :exchanges, "from_amount > 0",
                         name: "chk_exchanges_positive_amount"
  end
end
