class MarkCartAsAbandonedJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  def perform(cart_id)
    cart = Cart.find_by(id: cart_id)
    return if cart.nil?

    cart.mark_as_abandoned
  end
end
