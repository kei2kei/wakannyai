class Github::ReposController < ApplicationController
  before_action :authenticate_user!

  def index
    result = GithubService.new(current_user).list_repos
    if result[:success]
      @repos     = result[:repos]
      @return_to = params[:return_to]
    else
      redirect_to safe_return_path, alert: result[:error]
    end
  end

  def create
    repo_full_name = params[:repo_full_name]
    branch         = params[:branch].presence

    if repo_full_name.blank?
      redirect_to github_repos_path(return_to: params[:return_to]), alert: "レポジトリを選択してください。" and return
    end

    result = GithubService.new(current_user).set_repo!(full_name: repo_full_name, branch: branch)
    if result[:success]
      redirect_to(params[:return_to].presence || root_path, notice: "同期先を設定しました。")
    else
      redirect_to github_repos_path(return_to: params[:return_to]), alert: result[:error]
    end
  end

  private

  def safe_return_path
    rt = params[:return_to].to_s
    rt.present? && rt.start_with?("/") ? rt : (current_user.posts.first ? post_path(current_user.posts.first) : root_path)
  end
end
