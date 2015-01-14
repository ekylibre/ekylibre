class Pasteque::V5::CustomersController < Pasteque::V5::BaseController
  manage_restfully only: [:show, :update], model: :entity, scope: :clients, update_filters: {amount: :amount}

  def index
    if params[:mode] == 'top'
      params[:limit] ||= 10
      render json: Entity.best_clients(params[:limit].to_i).map(&:id)
    else
      @records = model.all
      render template: "layouts/pasteque/v5/index", locals:{output_name: 'customer', partial_path: 'customers/customer'}
    end
  end
end
