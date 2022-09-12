# frozen_string_literal: true

module Interventions
  class BuildDuplicate
    def initialize(intervention)
      @intervention = intervention
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      duplicate_intervention
      duplicate_working_periods
      duplicate_group_parameters
      duplicate_product_parameters
      duplicate_participations
      duplicate_receptions
      new_intervention
    end

    private
      attr_reader :intervention, :new_intervention

      def duplicate_intervention
        @new_intervention = intervention.dup
      end

      def duplicate_working_periods
        intervention.working_periods.each do |wp|
          new_intervention.working_periods.build(wp.dup.attributes)
        end
      end

      def duplicate_group_parameters
        intervention.group_parameters.each do |group_parameter|
          duplicate_group_parameter = group_parameter.dup
          duplicate_group_parameter.intervention = new_intervention
          %i[doers inputs outputs targets tools].each do |type|
            parameters = group_parameter.send(type)
            parameters.each do |parameter|
              duplicate_parameter = parameter.dup
              duplicate_parameter.group = duplicate_group_parameter
              duplicate_parameter.intervention = new_intervention
              duplicate_group_parameter.send(type) << duplicate_parameter
            end
          end
          new_intervention.group_parameters << duplicate_group_parameter
        end
      end

      def duplicate_product_parameters
        intervention.product_parameters.where(group_id: nil).each do |parameter|
          new_intervention.product_parameters << parameter.dup
        end
      end

      def duplicate_participations
        intervention.participations.includes(:working_periods).each do |participation|
          dup_participation = participation.dup.attributes.merge({ state: 'in_progress' })
          new_participation = new_intervention.participations.build(dup_participation)
          participation.working_periods.each do |wp|
            new_participation.working_periods.build(wp.dup.attributes)
          end
        end
      end

      def duplicate_receptions
        intervention.receptions.each do |reception|
          new_intervention.receptions << reception
        end
      end
  end
end
