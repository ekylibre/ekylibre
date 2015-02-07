class Pasteque::V5::BaseController < ActionController::Base
  include ExternalApiAdaptable
  before_action :authenticate_user!

  hide_action :authenticate_user!
  def authenticate_user!
    user, password = params[:user] || params[:login], params[:password]

    if user.blank? or password.blank?
      render status: :bad_request, json: {status: :rej, content: ["blank user or password: #{params.inspect}"]}
      return
    end

    unless @user = User.find_by(email: user.downcase)
      render status: :unauthorized, json: {status: :rej, content: ["no user found"]}
      return
    end

    unless @user.valid_password?(password)
      render status: :unauthorized, json: {status: :rej, content: @user.errors.full_messages}
      return
    end
  end
end
