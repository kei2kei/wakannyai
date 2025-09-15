class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :github_app

  def github_app
    auth = request.env["omniauth.auth"]
    @user = User.from_github_app_oauth(auth)
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message!(:notice, :success, kind: "Github") if is_navigational_format?
    else
      session["devise.github_app_data"] = auth.except(:extra)
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
