class GitHubService
  def initialize(user)
    @user = user
    @client = user.github_client
    @repo_name = "#{user.github_username}/learning-posts"
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
      @client.create_repository('learning-posts', {
        description: '学習中に躓いた内容の記録です。',
        private: false,
        auto_init: true
      })
      true
    rescue Octokit::Error => e
      Rails.logger.error "GitHub repository setup failed: #{e.message}"
      false
    end
  end

  def sync_post(post)
    return { success: false, error: 'GitHub連携が設定されていません' } unless can_sync?

    unless setup_repository
      return { success: false, error: 'リポジトリの準備に失敗しました' }
    end

    filename = "posts/#{post.created_at.strftime('%Y-%m-%d')}-#{post.title.parameterize}.md"
    content = generate_markdown_content(post)

    begin
      if post.github_sha.present?
        response = @client.update_contents(
          @repo_name,
          filename,
          "Update: #{post.title}",
          post.github_sha,
          content
        )
      else
        response = @client.create_contents(
          @repo_name,
          filename,
          "Add: #{post.title}",
          content
        )
      end

      # 投稿にGitHub情報を保存（github_shaカラムが必要）
      post.update!(
        github_url: response.content.html_url,
        github_sha: response.content.sha,
        github_synced_at: Time.current
      )

      { success: true, url: response.content.html_url }
    rescue Octokit::Error => e
      { success: false, error: e.message }
    end
  end

  private

  def generate_markdown_content(post)
    content = <<~MARKDOWN
      # #{post.title}

      **作成日**: #{post.created_at.strftime('%Y年%m月%d日')}
      **最終更新**: #{post.updated_at.strftime('%Y年%m月%d日')}

      #{post.content}

      ---

      *この投稿はわかんにゃいから自動同期されました*
    MARKDOWN

    Base64.encode64(content)
  end
end