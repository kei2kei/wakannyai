# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Images API", type: :request do
  let(:user) { create(:user) }

  describe "POST /api/upload-image" do
    before { sign_in user }

    it "画像をアップロードでき、JSONでurl/signed_idを返す" do
      file = fixture_file_upload("sample.jpg", "image/jpeg")
      post "/api/upload-image", params: { image: file }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["url"]).to start_with("/rails/active_storage/")
      expect(json["signed_id"]).to be_present

      # Blobが作られていて、metadata に uploader_id が入る
      blob = ActiveStorage::Blob.find_signed(json["signed_id"])
      expect(blob.metadata["uploader_id"].to_i).to eq(user.id)
    end

    it "サポート外のコンテンツタイプは 415" do
      file = fixture_file_upload("dummy.txt", "text/plain")
      post "/api/upload-image", params: { image: file }
      expect(response).to have_http_status(:unsupported_media_type)
    end

    it "サイズ超過は 413" do
      # 11MB の一時ファイルを用意（MAX_SIZE=10MB を想定）
      tf = Tempfile.new(["big", ".jpg"])
      tf.binmode
      tf.write("0" * (11 * 1024 * 1024))
      tf.rewind

      uploaded = Rack::Test::UploadedFile.new(tf.path, "image/jpeg")
      post "/api/upload-image", params: { image: uploaded }

      expect(response).to have_http_status(:payload_too_large)
      tf.close!
    end
  end

  describe "DELETE /api/images/:id" do
    let(:owner) { create(:user) }
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.jpg")),
        filename: "sample.jpg",
        content_type: "image/jpeg",
        metadata: { uploader_id: owner.id }
      )
    end

    it "アップローダー本人なら削除できる（204）" do
      sign_in owner
      delete "/api/images/#{blob.signed_id}"
      expect(response).to have_http_status(:no_content)
      expect { blob.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "他人は削除できず 403" do
      sign_in user
      delete "/api/images/#{blob.signed_id}"
      expect(response).to have_http_status(:forbidden)
      expect(ActiveStorage::Blob.exists?(blob.id)).to be true
    end
  end
end
