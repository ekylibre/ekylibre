# frozen_string_literal: true

module Interventions
  class AutolinkInterventionWithIncomingHarvestService
    attr_reader :incoming_harvest, :log_result

    def initialize(ih_ids)
      @incoming_harvest = IncomingHarvest.where(id: ih_ids)
      @log_result = {}
    end

    def perform
      @log_result[:intervention_count] = 0
      @log_result[:incoming_harvest_crop_count] = 0
      # group by day
      ih_groups = @incoming_harvest.reorder(:received_at).group_by { |i| i.received_at.to_date }
      ih_groups.each do |received_on, incoming_harvests|
        # get crops
        ihc_groups = IncomingHarvestCrop.where(incoming_harvest_id: incoming_harvests.pluck(:id)).reorder(:crop_id).group_by(&:crop_id)
        # group by crop
        ihc_groups.each do |crop_id, incoming_harvest_crops|
          # get the FIRST harvest intervention on same day and with crop as a target
          crop_harvest_intervention = find_harvest_intervention(crop_id, received_on)
          free_ihc = IncomingHarvestCrop.where(id: incoming_harvest_crops.map(&:id)).where(harvest_intervention_id: nil)
          if crop_harvest_intervention
            @log_result[:intervention_count] += 1
            crop_output = crop_harvest_intervention.outputs.first
            quantity_measure_to_set = free_ihc.map(&:harvest_quantity).compact.sum
            if crop_output && quantity_measure_to_set && quantity_measure_to_set.to_f > 0.0
              if crop_output.quantity.unit == quantity_measure_to_set.unit
                crop_output.quantity += quantity_measure_to_set
              elsif crop_output.quantity.unit != quantity_measure_to_set.unit
                crop_output.quantity = quantity_measure_to_set
              end
              crop_output.save!
              free_ihc.update_all(harvest_intervention_id: crop_harvest_intervention.id)
              @log_result[:incoming_harvest_crop_count] += free_ihc.count
            end
          end
        end
      end
      @log_result
    end

    private

      def find_harvest_intervention(crop_id, received_on)
        beginning_of_day = received_on.to_time.beginning_of_day
        end_of_day = received_on.to_time.end_of_day
        int_ids = Intervention.with_output_presence.where('(started_at >= ? AND started_at <= ?) OR (? BETWEEN started_at AND stopped_at) OR (? BETWEEN started_at AND stopped_at)', beginning_of_day, end_of_day, beginning_of_day, end_of_day)
        it = InterventionTarget.find_by(product_id: crop_id, intervention_id: int_ids.pluck(:id)) if int_ids.any?
        if it
          it.intervention
        else
          nil
        end
      end
  end
end
