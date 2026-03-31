class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string  :email,           null: false
      t.string  :password_digest, null: false
      t.string  :api_token,       null: false
      t.integer :lock_version,    null: false, default: 0
      t.timestamps null: false
    end

    add_index :users, :email,     unique: true
    add_index :users, :api_token, unique: true
  end
end
