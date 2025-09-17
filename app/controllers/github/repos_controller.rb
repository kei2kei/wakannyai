class Github::ReposController < ApplicationController
  before_action :authenticate_user!

  def index
    unless current_user.github_app_installation_id.present?
      redirect_to post_path(params[:return_to] || current_user.posts.first),
        alert: "まず GitHub App をインストールしてください。"
      return
    end

    client = GithubApp.installation_client(current_user.github_app_installation_id)

    repos_resp = client.list_app_installation_repositories
    @repos = repos_resp.repositories
    @return_to = params[:return_to]
  rescue Octokit::Error => e
    redirect_to root_path, alert: "レポジトリ一覧の取得に失敗しました: #{e.message}"
  end

  def create
    repo_full_name = params[:repo_full_name]
    branch = params[:branch].presence
    if repo_full_name.blank?
      redirect_to github_repos_path, alert: "レポジトリを選択してください。"
      return
    end

    current_user.update!(github_repo_full_name: repo_full_name, github_branch: branch)
    redirect_to(params[:return_to].presence || root_path, notice: "同期先を設定しました。")
  end
end
