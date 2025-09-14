require 'rails_helper'

RSpec.describe CartProduct, type: :model do
  context 'when validating' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product) }

    it 'validates numericality of quantity' do
      cart_prod = described_class.new(cart: cart, product: product, quantity: -1)
      expect(cart_prod.valid?).to be_falsey
      expect(cart_prod.errors[:quantity]).to include("must be greater than or equal to 0")
    end

    it 'validates uniquenesses of a product' do
      cart.cart_products.create(product: product, quantity: 1)

      cart_prod = described_class.new(cart: cart, product: product, quantity: 1)
      expect(cart_prod.valid?).to be_falsey
      expect(cart_prod.errors[:product_id]).to include("has already been taken")
    end
  end

  # context 'callbacks' do
  #   context 'when a cart_product is added or edited' do
  #     let(:cart) { create(:cart) }
  #     let(:product) { create(:product) }

  #     it 'calls update_cart_total_price after save' do
  #       expect_any_instance_of(Cart).to receive(:update_total_price)
  #       expect_any_instance_of(Cart).to receive(:update_last_active_interaction)
  #       create(:cart_product, cart: cart, product: product)
  #     end
  #   end

  #   context 'when a cart_product is destroyed' do
  #     let(:cart_destroyed) { create(:cart) }

  #     it 'calls update_cart_total_price after destroy' do
  #       cart_product = create(:cart_product, cart: cart_destroyed)

  #       expect_any_instance_of(Cart).to receive(:update_total_price).at_least(:once)
  #       expect_any_instance_of(Cart).to receive(:update_last_active_interaction)
  #       cart_product.destroy
  #     end
  #   end
  # end
end
