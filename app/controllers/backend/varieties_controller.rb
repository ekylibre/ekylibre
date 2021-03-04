module Backend
  class VarietiesController < Backend::BaseController
    def selection
      @varieties = Onoma::Variety.selection_hash(params[:specie])
    end
  end
end
