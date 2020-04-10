class InterventionParameter
  class LoggedPhytosanitaryProduct
    include Ekylibre::Model

    ATTRIBUTES = %i[state mix_category_codes allowed_mentions].freeze

    attr_accessor *ATTRIBUTES

    def allowed_for_organic_farming?
      allowed_mentions.present? && allowed_mentions.keys.include?('organic_usage')
    end

    def withdrawn?
      state == 'withdrawn'
    end
  end
end
