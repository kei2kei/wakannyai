require "uri"

class GithubService
  def initialize(user)
    @user = user
  end

  # idの確認（ユーザーが削除していた場合のため）
  def link_installation!(installation_id)
    client = GithubApp.installation_client(installation_id)
    return err(:installation_inaccessible, "この installation はアクセスできません。正しいアカウントでインストールしてください。") unless client

    @user.update!(github_app_installation_id: installation_id, github_repo_full_name: nil, github_branch: nil)
    ok
  end

  def list_repos
    installation = ensure_installation!
    return installation unless installation[:ok]

    repos = installation[:client].list_app_installation_repositories.repositories
    ok(repos: repos)
  rescue Octokit::Error => e
    err(:octokit, "レポジトリ一覧の取得に失敗しました: #{e.message}")
  end

  def set_repo!(full_name:, branch: nil)
    return err(:missing_installation, "まず GitHub App をインストールしてください") unless @user.github_app_installation_id.present?

    @user.update!(github_repo_full_name: full_name, github_branch: branch.presence)
    ok
  end

  def sync_post!(post)
    installation = ensure_installation!
    return installation unless installation[:ok]
    client = installation[:client]

    repo_status = ensure_repo!
    return repo_status unless repo_status[:ok]

    repo   = @user.github_repo_full_name
    branch = @user.github_branch.presence || client.repo(repo).default_branch

    path = build_post_path(post)
    content_markdown = sync_and_replace_image_urls(post, client, repo, branch)
    return err(:images, "画像同期でエラーが発生しました") unless content_markdown

    content   = generate_markdown_content(post, content_markdown)
    existing  = begin
                  client.contents(repo, path: path, ref: branch)
                rescue Octokit::NotFound
                  nil
                end
    msg       = existing ? "Update post ##{post.id}" : "Add post ##{post.id}"
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
    ok(url: html_url)

  rescue Octokit::Unauthorized, Octokit::Forbidden
    err(:permission, "GitHub の権限が不足しています。アプリの権限/インストールを確認して再連携してください。")
  rescue Octokit::NotFound
    @user.update!(github_repo_full_name: nil, github_branch: nil)
    err(:repo_not_found, "リポジトリが見つかりません。同期先を選び直してください。")
  rescue Octokit::Error => e
    Rails.logger.error "GitHub post sync failed: #{e.message}"
    err(:octokit, e.message)
  end
  private

  def ensure_installation!
    return err(:missing_installation, "まず GitHub App をインストールしてください") unless @user.github_app_installation_id.present?

    client = GithubApp.installation_client(@user.github_app_installation_id)
    unless client
      reset_linkage!
      return err(:installation_inaccessible, "GitHub App がアンインストールされたようです。再連携してください。")
    end
    ok(client: client)
  rescue Octokit::Unauthorized, Octokit::Forbidden, Octokit::NotFound => e
    Rails.logger.warn "GitHub installation access error: #{e.class} #{e.message}"
    err(:octokit, "GitHub 連携にアクセスできませんでした（#{e.class}）。再連携をお試しください。")
  end

  def ensure_repo!
    return err(:missing_repo, "同期先レポジトリを選択してください") unless @user.github_repo_full_name.present?
    ok
  end

  def reset_linkage!
    @user.update!(github_app_installation_id: nil, github_repo_full_name: nil, github_branch: nil)
  end

  def build_post_path(post)
    slug = parameterize(post.title)
    slug = slug.presence || "post-#{post.id}"
    "wakannyai_posts/#{slug}.md"
  end

  def default_branch(client, repo_full_name)
    client.repo(repo_full_name).default_branch
  end

  def parameterize(str)
      str.downcase
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
    data = blob.download
    timestamp  = Time.current.strftime("%Y%m%d%H%M%S")
    extension  = File.extname(blob.filename.to_s).presence || ".bin"
    base       = I18n.transliterate(File.basename(blob.filename.to_s, extension)).gsub(/[^a-zA-Z0-9\-]/, "_").downcase
    path       = "wakannyai_posts/#{post.id}/images/#{timestamp}_#{base}#{extension}"

    begin
      response = client.create_contents(repo, path, "Add image for post ##{post.id}", data, branch: branch)
      response.dig(:content, :download_url)
    rescue Octokit::UnprocessableEntity
      escaped = path.split("/").map { |seg| ERB::Util.url_encode(seg) }.join("/")
      "https://raw.githubusercontent.com/#{repo}/#{branch}/#{escaped}"
    end
  end

  def ok(**extra)  = { ok: true, success: true }.merge(extra)
  def err(code, msg) = { ok: false, success: false, code: code, error: msg }
end
