require 'rails_helper'

RSpec.describe "/carts", type: :request do
  describe "POST /add_item" do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }
    let!(:cart_item) { create(:cart_product, cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      subject do
        post '/cart/add_item', params: { product_id: product.id, quantity: 1, cart_id: cart.id }, as: :json
        post '/cart/add_item', params: { product_id: product.id, quantity: 1, cart_id: cart.id }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        current_time = Time.current
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
        cart.reload
        expect(cart.total_price).to eq(BigDecimal("10.0") * 3)
        expect(cart.last_interaction_at).to be_within(1.minute).of(current_time)
      end
    end

    context 'with a invalid quantity' do
      it 'return error' do
        post '/cart/add_item', params: { product_id: product.id, quantity: -1, cart_id: cart.id }, as: :json
        json_response = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json_response["errors"]).to include('Quantity not allowed')
      end
    end

    context 'when the product is not in the cart' do
      before do
        cart.cart_products.destroy_all
      end

      it 'returns error' do
        post '/cart/add_item', params: { product_id: product.id, quantity: 1, cart_id: cart.id }, as: :json
        json_response = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json_response["errors"]).to include('Item is not present on cart')
      end
    end
  end

  describe "DELETE /remove_item" do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }
    let!(:cart_item) { create(:cart_product, cart: cart, product: product, quantity: 1) }

    context 'when item is not in the cart' do
      it 'returns error' do
        delete "/cart/999", params: { cart_id: cart.id}, as: :json
        json_response = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json_response["errors"]).to include('Item is not present on cart')
      end
    end

    context 'when item is present on the cart' do
      it 'removes the item and returns the cart current state' do
        current_time = Time.current
        delete "/cart/#{product.id}", params: { cart_id: cart.id}, as: :json
        json_response = JSON.parse(response.body)
        cart.reload

        expect(response).to have_http_status(:ok)

        expect(cart.products.size).to eq(0)
        expect(cart.total_price).to eq(BigDecimal("0.0"))
        expect(cart.last_interaction_at).to be_within(1.minute).of(current_time)

        expect(json_response.keys).to include('id', 'products', 'total_price')
        expect(json_response['products'].size).to eq(0)
      end
    end
  end

  describe "POST /cart" do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }

    context "when product exists and is not in the cart" do
      it "creates the cart_product and returns the cart" do
        current_time = Time.current
        post "/cart", params: { product_id: product.id, quantity: 2, cart_id: cart.id }, as: :json
        json_response = JSON.parse(response.body)
        cart.reload

        expect(response).to have_http_status(:ok)
        expect(json_response["id"]).to eq(cart.id)
        expect(cart.cart_products.find_by(product_id: product.id).quantity).to eq(2)

        expect(cart.total_price).to eq(BigDecimal("10.0") * 2)
        expect(cart.last_interaction_at).to be_within(1.minute).of(current_time)
      end
    end

    context 'when product does not exists' do
      it 'returns not found status' do
        post "/cart", params: { product_id: 222, quantity: 2, cart_id: cart.id }, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when product is already in the cart" do
      before do
        create(:cart_product, cart: cart, product: product)
        cart.reload
      end

      it "returns error" do
        post "/cart", params: { product_id: product.id, quantity: 1, cart_id: cart.id }, as: :json
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(json_response["errors"]).to include("Item already present on cart")
      end
    end

    context "when cart_product fails to persist" do
      before do
        allow_any_instance_of(CartProduct).to receive(:persisted?).and_return(false)
      end

      it "returns the error messages" do
        post "/cart", params: { product_id: product.id, quantity: 1, cart_id: cart.id }, as: :json
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(json_response.keys).to include('errors')
      end
    end

    context 'when cart is not in session' do
      it 'creates a new cart and store in session' do
        current_time = Time.current
        post "/cart", params: { product_id: product.id, quantity: 1 }, as: :json
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(json_response['id']).not_to eq(cart.id)

        new_cart = Cart.find(json_response['id'])
        expect(new_cart.total_price).to eq(BigDecimal("10.0"))
        expect(new_cart.last_interaction_at).to be_within(1.minute).of(current_time)
      end
    end
  end

  describe "GET /show" do
    it 'returns the current cart data' do
      get '/cart'

      json_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json_response.keys).to include("id", "products", "total_price")
    end
  end
end
