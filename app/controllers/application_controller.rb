class ApplicationController < ActionController::Base
  # before_action :authenticate_user!
  # before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def new_session_path(scope)
    new_user_session_path
  end
end
