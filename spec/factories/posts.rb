FactoryBot.define do
  factory :post do
    title { "Test Post Title" }
    content { "Test post content." }
    association :user

    trait :with_images do
      after(:build) do |post|
        file_path = Rails.root.join('spec', 'fixtures', 'files', 'test_image.png')
        post.images.attach(io: File.open(file_path), filename: 'test_image.png', content_type: 'image/png')
      end
    end
  end
end