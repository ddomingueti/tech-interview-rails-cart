class ClearAbandonedCartsCronJob
  include Sidekiq::Job
  sidekiq_options retry: 3

  # Runs once in day to force the execution of carts with a invalid state on databases
  def perform(*args)
    Cart.active.where("last_interaction_at < ?", Cart::MINIMUM_ABANDONED_INTERVAL.ago).find_each do |cart|
      cart.mark_as_abandoned
    end

    Cart.abandoned.where("last_interaction_at < ?", Cart::MAXIMUM_ABANDONED_INTERVAL.ago).find_each do |cart|
      cart.remove_if_abandoned
    end
  end
end
