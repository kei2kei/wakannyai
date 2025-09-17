require "uri"

class GithubService
  def initialize(user)
    @user = user
  end

  def can_sync?
    @user.github_app_installation_id.present? && @user.github_repo_full_name.present?
  end

  def sync_post(post)
    return { success: false, error: "GitHub App が未連携です" } unless can_sync?

    begin
      client = GithubApp.installation_client(@user.github_app_installation_id)
    rescue GithubApp::InstallationMissing
      return { success: false, error: "GitHub App がアンインストールされています。『連携する』から再接続してください。" }
    rescue Octokit::Unauthorized, Octokit::Forbidden, Octokit::NotFound => e
      Rails.logger.warn "GitHub installation access error: #{e.class} #{e.message}"
      return { success: false, error: "GitHub 連携にアクセスできませんでした（#{e.class}）。再連携をお試しください。" }
    end
    repo   = @user.github_repo_full_name
    branch = @user.github_branch.presence || default_branch(client, repo)

    path = build_post_path(post)
    content_markdown = sync_and_replace_image_urls(post, client, repo, branch)
    return { success: false, error: "画像同期でエラーが発生しました" } unless content_markdown

    content = generate_markdown_content(post, content_markdown)

    begin
      existing = client.contents(repo, path: path, ref: branch) rescue nil
      msg = existing ? "Update post ##{post.id}" : "Add post ##{post.id}"
      committer = { name: @user.name, email: @user.email.presence || "noreply@example.com" }

      response =
        if existing
          client.update_contents(repo, path, msg, existing.sha, content,
                                branch: branch, committer: committer, author: committer)
        else
          client.create_contents(repo, path, msg, content,
                                branch: branch, committer: committer, author: committer)
        end

      html_url = response.dig(:content, :html_url)
      post.update!(github_url: html_url, github_synced_at: Time.current)
      { success: true, url: html_url }

    rescue Octokit::Unauthorized, Octokit::Forbidden
      { success: false, error: "GitHub の権限が不足しています。アプリの権限/インストールを確認して再連携してください。" }
    rescue Octokit::Error => e
      Rails.logger.error "GitHub post sync failed: #{e.message}"
      { success: false, error: e.message }
    end
  end

  private
  def build_post_path(post)
    slug = parameterize(post.title)
    slug = slug.presence || "post-#{post.id}"
    "wakannyai_posts/#{slug}.md"
  end

  def default_branch(client, repo_full_name)
    client.repo(repo_full_name).default_branch
  end

  def parameterize(str)
    I18n.transliterate(str.to_s)
        .downcase
        .gsub(/[^a-z0-9]+/, "-")
        .gsub(/^-|-$/, "")
  end

  def generate_markdown_content(post, content_with_images)
    <<~MD
      # #{post.title}

      **作成日**: #{post.created_at.strftime("%Y/%m/%d")}
      **最終更新**: #{post.updated_at.strftime("%Y/%m/%d")}

      #{content_with_images}
    MD
  end

  def sync_and_replace_image_urls(post, client, repo, branch)
    md = post.content.to_s.dup
    md.scan(/!\[[^\]]*\]\(([^)]+)\)/).flatten.uniq.each do |url|
      next unless url.include?("/rails/active_storage/")
      blob = extract_blob_from_url(url)
      next unless blob

      gh_url = upload_image_to_github(client, repo, branch, post, blob)
      return nil unless gh_url
      md.gsub!(url, gh_url)
    end
    md
  end

  def extract_blob_from_url(url)
    if (m = url.match(%r{/blobs(?:/(?:redirect|proxy))?/([^/?#]+)}))
      ActiveStorage::Blob.find_signed(m[1]) rescue nil
    elsif (m = url.match(%r{/representations/redirect/([^/]+)}))
      ActiveStorage::Blob.find_signed(m[1]) rescue nil
    end
  end


  def upload_image_to_github(client, repo, branch, post, blob)
    data    = blob.download

    timestamp   = Time.current.strftime("%Y%m%d%H%M%S")
    extension  = File.extname(blob.filename.to_s).presence || ".bin"
    base = I18n.transliterate(File.basename(blob.filename.to_s, extension))
              .gsub(/[^a-zA-Z0-9\-]/, "_").downcase
    path = "wakannyai_posts/#{post.id}/images/#{timestamp}_#{base}#{extension}"

    begin
      response = client.create_contents(
        repo, path, "Add image for post ##{post.id}", data,
        branch: branch
      )
      response.dig(:content, :download_url)
    rescue Octokit::UnprocessableEntity
      escaped = path.split("/").map { |seg| ERB::Util.url_encode(seg) }.join("/")
      "https://raw.githubusercontent.com/#{repo}/#{branch}/#{escaped}"
    end
  end
end
