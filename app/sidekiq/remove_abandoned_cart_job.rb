class RemoveAbandonedCartJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  def perform(cart_id)
    cart = Cart.find_by(id: cart_id)
    return if cart.nil?

    cart.remove_if_abandoned
  end
end
