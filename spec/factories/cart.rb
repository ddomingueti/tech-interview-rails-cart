FactoryBot.define do
  factory :cart do
    status { 'active' }
    next_abandoned_job_jid { '' }
    next_removed_job_jid { '' }
    last_interaction_at { nil }
    total_price { 0 }

    trait :with_abandoned_status do
      status { 'abandoned' }
      last_interaction_at { 3.hours.ago }
    end

    trait :with_2_products do
      after(:create) do |cart|
        create_list(:cart_product, 2, cart: cart)
        cart.update_total_price
        cart.reload
      end
    end
  end
end
