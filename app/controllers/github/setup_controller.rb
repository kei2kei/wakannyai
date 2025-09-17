class Github::SetupController < ApplicationController
  before_action :authenticate_user!

  def update
    installation_id = params[:installation_id]
    if installation_id.present?
      current_user.update!(github_app_installation_id: installation_id)
      redirect_to github_repos_path(return_to: params[:return_to]),
        notice: "GitHub App を連携しました。同期先レポジトリを選んでください。"
    else
      redirect_to root_path, alert: "installation_id が取得できませんでした。"
    end
  end
end
