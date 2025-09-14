class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_status
  rescue_from ActiveRecord::RecordInvalid, with: :bad_request

  def not_found_status
    head :not_found
  end

  def bad_request
    head :bad_request
  end

  def authenticate_cart
    return @current_cart if @current_cart.present?

    cart_id = session[:cart_id] || params[:cart_id]
    @current_cart = Cart.find_by(id: cart_id)

    if @current_cart.blank?
      @current_cart = Cart.create!(total_price: 0)
      session[:cart_id] = @current_cart.id
    end
    @current_cart
  end

  def current_cart
    @current_cart
  end
end
