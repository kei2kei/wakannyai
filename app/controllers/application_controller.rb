class ApplicationController < ActionController::Base
  before_action :user_signed_in?
  before_action :configure_permitted_parameters, if: :devise_controller?

  def not_authenticated
    redirect_to login_path, alert: "ログインしてください。"
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end
end
