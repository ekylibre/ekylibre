class Pasteque::V5::ResourcesController < Pasteque::V5::BaseController
  #manage_restfully only: [:show], get_filters: {label: :name}, model: :resource
  def show
    render status: :not_found, json: nil
  end
end
