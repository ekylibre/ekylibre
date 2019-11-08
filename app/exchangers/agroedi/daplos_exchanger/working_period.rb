module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class WorkingPeriod < DaplosNode
      DEFAULT_DURATION = 61.seconds

      daplos_parent :intervention

      delegate :started_at, :stopped_at, to: :intervention

      def uid
        to_attributes.hash
      end

      def to_attributes
        stop = started_at + duration
        {
          started_at: started_at.strftime('%Y-%m-%d %H:%M'),
          stopped_at: stop.strftime('%Y-%m-%d %H:%M'),
          duration: duration
        }
      end

      def duration
        return @duration if @duration
        @duration = daplos_duration || work_time_duration || DEFAULT_DURATION
      end

      def discardable?
        !daplos_duration.present?
      end

      private

        def daplos_duration
          duration = daplos.intervention_duration
          empty_duration = duration&.match(/^0+$/)
          return nil unless duration.present? && !empty_duration
          j = duration[0, 2].to_i.days
          h = duration[2, 2].to_i.hours
          s = duration[4, 2].to_i.minutes
          duration = j + h + s
          start + duration
        end

        def work_time_duration
          flows = InterventionModel.where(procedure_reference: intervention.procedure.name, working_flow_unit: 'ha/h')
          return unless flows.any?
          inverse_speed = flows.average(:working_flow)
          working_area = intervention.working_zone_area
          return unless inverse_speed.to_d > 0.0 && working_area.to_f > 0.0
          duration = (inverse_speed.to_d * working_area.to_d).hours
          duration
        end
    end
  end
end

