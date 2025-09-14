require "rails_helper"

RSpec.describe "Images API", type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  let(:user) { create(:user, :github_authenticated) }

  before { login_as(user, scope: :user) }

  describe "POST /api/upload-image" do
    it "アップロードに成功し、srcset/sizes/signed_id/metadataを返す" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")

      post "/api/upload-image", params: { image: file }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["url"]).to be_present
      expect(json["srcset"]).to include("800w").and include("1600w")
      expect(json["sizes"]).to be_present
      expect(json["signed_id"]).to be_present
      expect(json["blob_id"]).to be_present

      blob = ActiveStorage::Blob.find(json["blob_id"])
      expect(blob.metadata["uploader_id"]).to eq(user.id)
    end

    it "サイズ超過は 413 を返す" do
      big = Tempfile.new(["big", ".jpg"])
      big.binmode
      big.write("0" * 11.megabytes)  # MAX_SIZE 10MB を超過
      big.rewind

      file = Rack::Test::UploadedFile.new(big.path, "image/jpeg")
      post "/api/upload-image", params: { image: file }

      expect(response).to have_http_status(:payload_too_large)
    ensure
      big.close! if big
    end

    it "不正なコンテンツタイプは 415 を返す" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/bad.txt"), "text/plain")
      post "/api/upload-image", params: { image: file }

      expect(response).to have_http_status(:unsupported_media_type)
    end
  end

  describe "DELETE /api/images/:id" do
    it "自分がアップした signed_id なら削除できる（204）" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.jpg")),
        filename: "sample.jpg",
        content_type: "image/jpeg",
        metadata: { "uploader_id" => user.id }
      )

      delete "/api/images/#{blob.signed_id}"

      expect(response).to have_http_status(:no_content)
      expect { blob.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "他人がアップしたものは 403" do
      other = create(:user)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.jpg")),
        filename: "sample.jpg",
        content_type: "image/jpeg",
        metadata: { "uploader_id" => other.id }
      )

      delete "/api/images/#{blob.signed_id}"

      expect(response).to have_http_status(:forbidden)
      expect { blob.reload }.not_to raise_error
    end

    it "存在しない/壊れたIDは 404" do
      delete "/api/images/bogus"
      expect(response).to have_http_status(:not_found)
    end
  end
end
