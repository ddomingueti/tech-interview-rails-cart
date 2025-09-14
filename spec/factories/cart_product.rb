FactoryBot.define do
  factory :cart_product do
    product { create :product }
    association :cart
    quantity { 1 }
  end
end
