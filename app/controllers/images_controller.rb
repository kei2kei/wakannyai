class ImagesController < ApplicationController
  MAX_SIZE = 10.megabytes
  ALLOWED = %w[image/png image/jpeg image/gif image/webp]
  def upload
    uploaded_file = params[:image]
    return render json: { error: 'ファイルが添付されませんでした。' }, status: :unprocessable_entity unless uploaded_file
    return render json: { error: 'ファイルサイズが大きすぎます。' }, status: :payload_too_large if uploaded_file.size.to_i > MAX_SIZE

    detected = Marcel::MimeType.for(uploaded_file.tempfile, name: uploaded_file.original_filename)
    return render json: { error: 'ファイルタイプが無効です。' }, status: :unsupported_media_type unless ALLOWED.include?(detected)

    if uploaded_file.present?
      begin
        blob = ActiveStorage::Blob.create_and_upload!(
          io: uploaded_file.tempfile,
          filename: uploaded_file.original_filename,
          content_type: detected,
          metadata: { uploader_id: current_user.id }
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
      blob = ActiveStorage::Blob.find_signed(params[:id])
      return head :not_found unless blob

      # 所有者チェック（metadata は文字列化されることが多いので to_i で吸収）
      uploader_id = blob.metadata&.[]('uploader_id').to_i
      return head :forbidden unless uploader_id == current_user.id

      blob.purge
      head :no_content
    rescue => e
      Rails.logger.error "画像の削除に失敗しました。: #{e.message}"
      render json: { error: '画像の削除に失敗しました。' }, status: :internal_server_error
    end
  end
end
