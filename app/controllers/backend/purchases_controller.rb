module Backend
  class PurchasesController < Backend::BaseController
    def show
      purchase = Purchase.find(params[:id])
      redirect_to(controller: purchase.model_name.route_key, action: :show, id: purchase.id)
    end
  end
end
