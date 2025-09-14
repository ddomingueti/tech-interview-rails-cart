class Cart < ApplicationRecord
  has_many :cart_products, dependent: :destroy
  has_many :products, through: :cart_products

  enum status: { active: 0, abandoned: 1 }

  MINIMUM_ABANDONED_INTERVAL = 3.hours
  MAXIMUM_ABANDONED_INTERVAL = 7.days

  after_save :schedule_abandoned_check

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  def update_total_price
    total_price = cart_products.sum { |cart_prod| cart_prod.product.price * cart_prod.quantity }
    update(total_price: total_price)
  end

  def update_last_active_interaction
    update(status: 'active', last_interaction_at: Time.current)
  end

  def mark_as_abandoned
    return if last_interaction_at.present? && last_interaction_at > MINIMUM_ABANDONED_INTERVAL.ago

    update(status: 'abandoned', next_abandoned_job_jid: nil)
    destroy_sidekiq_job(next_removed_job_jid) if next_removed_job_jid.present?
    jid = RemoveAbandonedCartJob.perform_in(MAXIMUM_ABANDONED_INTERVAL + 1.minute, id)
    update_columns(next_removed_job_jid: jid)
  end

  def remove_if_abandoned
    destroy! if abandoned? && last_interaction_at.present? && last_interaction_at < MAXIMUM_ABANDONED_INTERVAL.ago
  end

  def serializable_hash
    products = cart_products.map do |cp|
      {
        id: cp.product.id,
        name: cp.product.name,
        quantity: cp.quantity,
        unit_price: cp.product.price.to_f,
        total_price: cp.total_price.to_f
      }
    end

    {
      id: id,
      products: products,
      total_price: total_price
    }
  end

  private

  def schedule_abandoned_check
    return if abandoned?

    if active? && next_removed_job_jid.present?
      destroy_sidekiq_job(next_removed_job_jid)
      update_columns(next_removed_job_jid: nil)
    end

    destroy_sidekiq_job(next_abandoned_job_jid) if next_abandoned_job_jid.present?
    jid = MarkCartAsAbandonedJob.perform_in(MINIMUM_ABANDONED_INTERVAL + 1.minute, id)
    update_columns(next_abandoned_job_jid: jid)
  end

  def destroy_sidekiq_job(jid)
    Sidekiq::ScheduledSet.new.find_job(jid)&.delete
  end
end
