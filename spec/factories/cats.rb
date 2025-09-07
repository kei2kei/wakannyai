FactoryBot.define do
  factory :cat do
    association :user
    level { 1 }
    color { "orange" }
  end
end