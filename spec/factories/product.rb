FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    price { rand(10.0..200.0).round(2) }
  end
end
