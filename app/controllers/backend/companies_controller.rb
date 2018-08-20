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
      @company.nature = :organization
      @company.save
      # Update preferences
      ActiveRecord::Base.transaction do
        params[:preferences].each do |key, data|
          preference = Preference.get!(key)
          preference.reload
          if key == 'currency'
            gc = GlobalCurrency.new(preference.value)
            if preference.value.to_s != data[:value]
              rate = params[:currency_change_rate].to_i
              raise 'Cannot proceed with null rate' if rate.zero?
              gc.convert_to(data[:value], rate: rate)
            end
          end
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
