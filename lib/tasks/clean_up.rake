
namespace :clean_up do
  desc "投稿と紐づいていない古い画像(24h超)を削除する"
  task unattached_images: :environment do
    cutoff = 24.hours.ago

    scope = ActiveStorage::Blob.unattached
                               .where('active_storage_blobs.created_at < ?', cutoff)

    count = 0
    scope.find_each(batch_size: 500) do |blob|
      # 競合対策：直前で誰かが添付したら飛ばす
      next if blob.attachments.exists?

      # 背景ジョブが無い運用でも確実に消えるよう同期削除
      blob.purge  # ※ Sidekiq 等があるなら purge_later でもOK
      count += 1
    rescue => e
      Rails.logger.warn("[clean_up] purge failed for blob=#{blob.id}: #{e.class}: #{e.message}")
    end

    Rails.logger.info "[clean_up] purged #{count} blobs older than #{cutoff}"
  end
end
