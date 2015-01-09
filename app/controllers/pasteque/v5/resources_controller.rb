class Pasteque::V5::ResourcesController < Pasteque::V5::BaseController
  #manage_restfully only: [:index, :show]
  def index
    render status: :not_found, json:{message: :not_found}
  end

  def show
    render status: :not_found, json:{message: :not_found}
  end
end
