FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "test#{n}@example.com" }

    trait :github_authenticated do
      github_token { "mock_github_token" }
      github_username { "test_user_github" }
    end
  end
end