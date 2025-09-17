FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "test-#{n}-#{SecureRandom.hex(4)}@example.com" }

    trait :with_github_app do
      github_app_installation_id { 123456789 }
      github_repo_full_name      { "someone/learning-logs" }
      github_branch              { "main" }
      github_username            { "test_user_github" }
    end
  end
end