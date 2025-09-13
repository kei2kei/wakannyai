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

        render json: {
          url: rails_blob_path(blob, only_path: true),
          blob_id: blob.id,
          signed_id: blob.signed_id
        }, status: :created
      rescue => e
        Rails.logger.error "Image upload failed: #{e.message}"
        render json: { error: 'Image upload failed' }, status: :internal_server_error
      end
    else
      render json: { error: 'No file provided' }, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      blob = ActiveStorage::Blob.find_by(id: params[:id])

      if blob
        blob.purge
        head :no_content
      else
        head :not_found
      end
    rescue => e
      Rails.logger.error "Image deletion failed: #{e.message}"
      render json: { error: 'Image deletion failed' }, status: :internal_server_error
    end
  end
end
