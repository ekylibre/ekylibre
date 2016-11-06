module Backend
  class CompaniesController < Backend::BaseController
    def edit
      Preference.check!
      @company = Entity.of_company
    end

    def update
      # Update company
      @company = Entity.of_company
      @company.update_attributes(permitted_params[:entity])
      # Update preferences
      ActiveRecord::Base.transaction do
        params[:preferences].each do |key, data|
          preference = Preference.get!(key)
          preference.reload
          preference.value = data[:value]
          preference.save
        end
      end
      render :edit
    end

    protected

    def permitted_params
      params.permit!
    end
  end
end
