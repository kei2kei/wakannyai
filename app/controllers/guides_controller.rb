class GuidesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:help]
  def help; end
end
