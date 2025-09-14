RSpec.configure do |config|
  config.after(:each) do
    # テスト間で溜まりがちなBlobを掃除（必要なら絞ってOK）
    ActiveStorage::Blob.all.each { |b| b.purge_later rescue nil }
  end
end
