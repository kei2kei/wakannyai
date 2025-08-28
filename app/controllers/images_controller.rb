class ImagesController < ApplicationController
  def upload
    uploaded_file = params[:image]

    if uploaded_file.present?
      begin
        blob = ActiveStorage::Blob.create_and_upload!(
          io: uploaded_file.open,
          filename: uploaded_file.original_filename,
          content_type: uploaded_file.content_type
        )

        # 保存した画像のURLをActive Storageのヘルパーで取得し、JSONで返す
        render json: { url: url_for(blob) }, status: :created
      rescue => e
        Rails.logger.error "Image upload failed: #{e.message}"
        render json: { error: 'Image upload failed' }, status: :internal_server_error
      end
    else
      render json: { error: 'No file provided' }, status: :unprocessable_entity
    end
  end
end
