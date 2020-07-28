class InterventionParameter
  class LoggedPhytosanitaryUsage
    include Dimensionable
    include Ekylibre::Model

    ATTRIBUTES = %i[decision_date state dose_quantity dose_unit dose_unit_name dose_unit_factor untreated_buffer_aquatic applications_count usage_conditions
                    untreated_buffer_arthropod pre_harvest_delay development_stage_min development_stage_max untreated_buffer_plants crop_label_fra
                    applications_frequency ephy_usage_phrase].freeze

    attr_accessor *ATTRIBUTES, :in_field_reentry_delay, :france_maaid

    def decorated_development_stage_min
      if development_stage_min && !development_stage_max
        "Min : #{development_stage_min}"
      elsif !development_stage_min && development_stage_max
        "Max : #{development_stage_max}"
      elsif development_stage_min && development_stage_max
        "#{development_stage_min} - #{development_stage_max}"
      end
    end

    def decorated_reentry_delay
      return unless in_field_reentry_delay
      if in_field_reentry_delay.in_full(:hour) == 6
        "#{in_field_reentry_delay.in_full(:hour)} h (8 h #{:if_closed_environment.tl})"
      else
        "#{in_field_reentry_delay.in_full(:hour)} h"
      end
    end

    def in_field_reentry_delay
      @in_field_reentry_delay.present? ? ActiveSupport::Duration.parse(@in_field_reentry_delay) : nil
    end

    def pre_harvest_delay
      @pre_harvest_delay.present? ? ActiveSupport::Duration.parse(@pre_harvest_delay) : nil
    end

    def applications_frequency
      @applications_frequency.present? ? ActiveSupport::Duration.parse(@applications_frequency) : nil
    end

    def dose_quantity
      @dose_quantity.present? ? @dose_quantity.to_d : nil
    end

    def withdrawn?
      state == 'withdrawn'
    end
  end
end
