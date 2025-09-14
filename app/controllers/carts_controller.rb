class CartsController < ApplicationController
  before_action :authenticate_cart

  def create
    product = Product.find_by(id: cart_params[:product_id])
    return not_found_status if product.blank?
    return render_error('Item already present on cart') if @current_cart.cart_products.find_by(product_id: product.id)

    cart_product = @current_cart.cart_products&.create(product: product, quantity: cart_params[:quantity])
    if cart_product.persisted?
      update_cart_data()
      render json: @current_cart.serializable_hash, status: :ok
    else
      render_error(cart_product)
    end
  end

  def show
    render json: @current_cart.serializable_hash, status: :ok
  end

  def add_item
    cart_product_item = @current_cart.cart_products.find_by(product_id: cart_params[:product_id])
    return render_error('Item is not present on cart') unless cart_product_item.present?
    return render_error('Quantity not allowed') unless valid_quantity?

    cart_product = cart_product_item.update(quantity: cart_params[:quantity] + cart_product_item.quantity)
    if cart_product
      update_cart_data()
      render json: @current_cart.serializable_hash, status: :ok
    else
      render_error(cart_product)
    end
  end

  def remove_item
    cart_product_item = @current_cart.cart_products.find_by(product_id: cart_params[:product_id])
    return render_error('Item is not present on cart') unless cart_product_item.present?

    if cart_product_item.destroy
      update_cart_data()
      render json: @current_cart.serializable_hash, status: :ok
    else
      render_error(cart_product_item)
    end
  end

  private

  def cart_params
    params.permit(:product_id, :quantity)
  end

  def render_error(record)
    errors = if record.respond_to?(:errors)
      record.errors.full_messages
    else
      Array(record)
    end

    render json: { errors: errors }, status: :bad_request
  end

  def valid_quantity?
    cart_params[:quantity].to_i > 0
  end

  def update_cart_data
    @current_cart.update_total_price
    @current_cart.update_last_active_interaction
    @current_cart.reload
  end
end
