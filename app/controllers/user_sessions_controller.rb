class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  def new; end

  def create
    @user = login(params[:email], params[:password])
    if @user
      flash[:success] = 'ログインしました。'
      redirect_to root_path
    else
      flash.now[:alert] = 'ログインに失敗しました。メールアドレスまたはパスワードが正しくありません。'
      render login_path, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    flash[:notice] = 'ログアウトしました。'
    redirect_to root_path
  end

  private

  def login_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
