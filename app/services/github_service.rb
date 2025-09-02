require 'uri'

class GithubService
  def initialize(user)
    @user = user
    @client = Octokit::Client.new(access_token: user.github_token)
    @repo_name = "#{user.github_username}/learning-logs"
  end

  def can_sync?
    @user.can_sync_to_github? && @client.present?
  end

  def setup_repository
    return false unless can_sync?

    begin
      @client.repository(@repo_name)
      true
    rescue Octokit::NotFound
      @client.create_repository('learning-logs', description: '学習中に躓いた内容の記録です。', private: false, auto_init: true)
      true
    rescue Octokit::Error => e
      Rails.logger.error "GitHub repository setup failed: #{e.message}"
      false
    end
  end

  def sync_post(post)
    return { success: false, error: 'GitHub連携が設定されていません' } unless can_sync?
    return { success: false, error: 'リポジトリの準備に失敗しました' } unless setup_repository

    content_with_github_images = sync_and_replace_image_urls(post)
    return { success: false, error: '画像同期中にエラーが発生しました' } unless content_with_github_images

    final_markdown_content = generate_markdown_content(post, content_with_github_images)
    filename = "learning_logs/#{post.title}.md"

    begin
      existing_file = @client.contents(@repo_name, path: filename)

      response = @client.update_contents(
        @repo_name,
        filename,
        "Updated post: #{post.title}",
        existing_file.sha,
        final_markdown_content
      )

    rescue Octokit::NotFound
      response = @client.create_contents(
        @repo_name,
        filename,
        "Add post: #{post.title}",
        final_markdown_content
      )
    end

    post.update!(
      github_url: response.content.html_url,
      github_synced_at: Time.current
    )
    { success: true, url: response.content.html_url }

  rescue Octokit::Error => e
    Rails.logger.error "GitHub post sync failed: #{e.message}"
    { success: false, error: "GitHubへの投稿同期に失敗しました: #{e.message}" }
  end

  private

  def sync_and_replace_image_urls(post)
    updated_content = post.content.dup
    regex = /!\[.*?\]\((https?:\/\/[^)]*\/rails\/active_storage\/[^)]+)\)/

    post.content.scan(regex).flatten.uniq.each do |original_url|
      blob_id = extract_blob_id_from_url(original_url)
      next unless blob_id

      blob = ActiveStorage::Blob.find_by(id: blob_id)
      next unless blob

      github_image_url = upload_image_to_github(post, blob)
      if github_image_url
        Rails.logger.info "URL置換: #{original_url} -> #{github_image_url}"
        updated_content = updated_content.gsub(original_url, github_image_url)
      else
        Rails.logger.error "GitHubへの画像アップロードに失敗しました: #{blob.filename}"
        return nil
      end
    end

    updated_content
  end

  def upload_image_to_github(post, blob)
    return nil unless blob

    begin
      image_data = blob.download

      timestamp = Time.current.strftime('%Y%m%d%H%M%S')
      original_filename = blob.filename.to_s
      extension = File.extname(original_filename)
      basename = File.basename(original_filename, extension)
      safe_basename = I18n.transliterate(basename).gsub(/[^a-zA-Z0-9\-]/, '_').downcase
      safe_filename = "#{timestamp}_#{safe_basename}#{extension}"
      github_path = "learning_logs/images/#{post.id}/#{safe_filename}"

      response = @client.create_contents(
        @repo_name,
        github_path,
        "Add image: #{original_filename}",
        image_data
      )
      return response.content.download_url

    rescue Octokit::Conflict
      encoded_path = ["learning_logs", "images", post.id.to_s, safe_filename].map do |s|
        URI.encode_www_form_component(s)
      end.join('/')
      existing_url = "https://raw.githubusercontent.com/#{@repo_name}/main/#{encoded_path}"
      Rails.logger.warn "画像は既に存在します: #{existing_url}"
      return existing_url

    rescue Octokit::Error => e
      Rails.logger.error "❌ GitHub画像アップロードエラー: #{e.message}"
      return nil
    end
  end

  def extract_blob_id_from_url(url)
    return nil unless url.include?('/rails/active_storage/')

    signed_id_patterns = [
      %r{/blobs/redirect/([^/]+)},
      %r{/blobs/proxy/([^/]+)},
      %r{/blobs/([^/]+)}
    ]

    signed_id_patterns.each do |pattern|
      if match = url.match(pattern)
        signed_id = match.captures.first.split('?').first
        begin
          return ActiveStorage.verifier.verify(signed_id, purpose: :blob_id)
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          next
        end
      end
    end
    Rails.logger.error "Blob IDの抽出に失敗しました: #{url}"
    nil
  end

  def generate_markdown_content(post, content)
    <<~MARKDOWN
      # #{post.title}

      **作成日**: #{post.created_at.strftime('%Y年%m月%d日')}
      **最終更新**: #{post.updated_at.strftime('%Y年%m月%d日')}

      #{content}
    MARKDOWN
  end
end