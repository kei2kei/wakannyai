FactoryBot.define do
  factory :cat do
    association :user # Userとの関連付けを自動で作成
    level { 1 }
    color { "orange" }
  end
end