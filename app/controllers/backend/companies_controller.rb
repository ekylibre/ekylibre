module Backend
  class CompaniesController < Backend::BaseController
    def edit
      Preference.check!
      @company = Entity.of_company
    end

    def update
      ActiveRecord::Base.transaction do
        # Update company
        @company = Entity.of_company
        @company.update_attributes(permitted_params[:entity])
        @company.nature = :organization
        @company.save!
        # Update preferences
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
          if preference.value != data[:value]
            old_value = preference.value
            preference.value = data[:value]
            preference.save!
            preference_changed(preference, old_value, data[:value])
          end
        end
      end
      render :edit
    end

    protected

    def permitted_params
      params.permit!
    end

    # Called after each change in a preference when updating the company
    # @param [Preference] preference
    # @param [Object] old_value
    # @param [Object] new_value
    def preference_changed(preference, old_value, new_value)
      account_number_digits_changed(old_value.to_i, new_value.to_i) if preference.name == "account_number_digits"
    end

    # Called after each change of the preference :account_number:digits when updating the company
    # @param [Integer] old_value
    # @param [Integer] new_value
    def account_number_digits_changed(old_value, new_value)
      return if JournalEntry.any?

      n = Accountancy::AccountNumberNormalizer.build(standard_length: new_value)
      Account.where.not(nature: "auxiliary")
             .each { |acc| acc.update!(number: n.normalize!(acc.number)) }
    end
  end
end
