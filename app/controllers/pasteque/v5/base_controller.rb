class Pasteque::V5::BaseController < BaseController
  include ExternalApiAdaptable
  skip_before_action :set_theme, :set_locale, :set_time_zone
  before_action :authenticate_user

  hide_action :authenticate_user
  def authenticate_user
    user, password = params[:user], params[:password]

    if user.blank? or password.blank?
      render status: :bad_request, json: {message: "The request must contain the user email and password."}
      return
    end

    unless @user = User.find_by(email: user.downcase)
      render status: :unauthorized, json: {message: "Invalid user or password."}
      return
    end

    unless @user.valid_password?(password)
      render status: :unauthorized, json: {message: "Invalid user or password."}
      return
    end
  end
end
