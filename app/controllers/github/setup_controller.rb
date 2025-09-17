class Github::SetupController < ApplicationController
  before_action :authenticate_user!

  def update
    installation_id = params[:installation_id]
    unless installation_id.present?
      redirect_to root_path, alert: "installation_id が取得できませんでした。" and return
    end

    result = GithubService.new(current_user).link_installation!(installation_id)
    if result[:success]
      redirect_to github_repos_path(return_to: params[:return_to]),
        notice: "GitHub App を連携しました。同期先レポジトリを選んでください。"
    else
      redirect_to root_path, alert: result[:error]
    end
  end
end
