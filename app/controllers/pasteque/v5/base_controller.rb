class Pasteque::V5::BaseController < ActionController::Base
  include ExternalApiAdaptable
  before_action :authenticate_user!

  # before_action do
  #   puts request.body.read.to_s.red
  # end

  # after_action do
  #   puts response.body.to_s.yellow
  # end

  hide_action :authenticate_user!
  def authenticate_user!
    user, password = params[:user] || params[:login], params[:password]

    if user.blank? or password.blank?
      render json: {status: :rej, content: ["blank user or password: #{params.inspect}"]}
      return
    end

    unless @user = User.find_by(email: user.downcase)
      render json: {status: :rej, content: ["no user found"]}
      return
    end

    unless @user.valid_password?(password)
      render json: {status: :rej, content: @user.errors.full_messages}
      return
    end
  end
end
