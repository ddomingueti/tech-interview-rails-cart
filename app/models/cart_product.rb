class CartProduct < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates_numericality_of :quantity, greater_than_or_equal_to: 0
  validates :product_id, uniqueness: { scope: :cart_id }

  # after_save :update_cart_data
  # after_destroy :update_cart_data

  def total_price
    return 0 if product.blank?

    quantity * product.price
  end

  # def update_cart_data
  #   cart.update_total_price
  #   cart.update_last_active_interaction
  # end
end
