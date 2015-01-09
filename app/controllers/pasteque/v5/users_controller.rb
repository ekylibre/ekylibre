class Pasteque::V5::UsersController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show]

  def update_password
    @user = User.find(params[:id])
    password = permitted_params[:newPwd]
    render json: @user.update(password: password)
  end
end
