class AddCartProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :cart_products do |t|
      t.references :cart, null: false, foreign_key: true, index: true
      t.references :product , null: false, foreign_key: true, index: true
      t.integer :quantity, default: 0, null: false

      t.timestamps
    end

    add_index :cart_products, [:cart_id, :product_id], unique: true
  end
end
