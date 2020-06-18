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
          # This is a nasty hack to use the type coercion of Preference in order to be able to compare values from the form and values inside the Preferences
          old_value = preference.value
          preference.value = data[:value]

          if old_value != preference.value # Here, preference.value is the 'new value'
            preference.save!
            preference_changed(preference, preference.value)
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
      # @param [Object] new_value
      def preference_changed(preference, new_value)
        account_number_digits_changed(new_value.to_i) if preference.name == "account_number_digits"
      end

      # Called after each change of the preference :account_number:digits when updating the company
      # @param [Integer] new_value
      def account_number_digits_changed(new_value)
        return if JournalEntry.any?

        n = Accountancy::AccountNumberNormalizer.build(standard_length: new_value)

        errors = Account.where.not(nature: "auxiliary")
                        .map { |acc| normalize_account(acc, normalizer: n) }
                        .select(&:is_some?)
                        .map(&:get)

        if errors.any?
          notify_error_now(
            :accounts_cannot_be_truncated_to_preference,
            accounts: errors.map(&:number).join(', '),
            preference: errors.first.standard_length,
            count: errors.size
          )

          raise ActiveRecord::Rollback
        end
      end

      # @todo use a Result type when available
      # @param [Account] account
      # @param [Accountancy::AccountNumberNormalizer] normalizer
      # @return [Maybe<Accountancy::AccountNumberNormalizer::NormalizationError>]
      def normalize_account(account, normalizer:)
        account.update(number: normalizer.normalize!(account.number))
        None()
      rescue Accountancy::AccountNumberNormalizer::NormalizationError => e
        return Some(e)
      end
  end
end
