class Pasteque::V5::BaseController < ActionController::Base
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
