FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "test#{n}@example.com" }
  end
end