# frozen_string_literal: true

module Interventions
  module Geolocation
    # Build intervention target attributes (including computed working zone) from rides
    class AttributesBuilderFromRides
      def self.call(*args)
        new(*args).call
      end

      def initialize(ride_ids:, procedure_name:, target_class: nil)
        @ride_ids = ride_ids
        @procedure_name = procedure_name
        @target_class = target_class
      end

      def call
        options = {
          targets_attributes: [],
          group_parameters_attributes: [],
          ride_ids: existing_rides.pluck(:id)
        }

        return options if target_parameter.nil?
        return options if existing_rides.blank?
        return options if matching_targets.blank?

        target_options = matching_targets.map do |target|
          target_working_zone = compute_target_working_zone(target.shape)
          {
            reference_name: target_parameter.name,
            product_id: target.id,
            working_zone: target_working_zone,
          }
        end

        if procedure = Procedo::Procedure.find(@procedure_name)
          existing_rides.first.ride_set.equipments.map(&:product).each_with_index do |equipment, index|
            procedure.parameters_of_type(:tool).each do |tool|
              next unless equipment.of_expression(tool.filter)

              options[:tools_attributes] ||= {}
              options[:tools_attributes][index.to_s] = { reference_name: tool.name, product_id: equipment.id }
              break
            end
          end
        end

        options[:working_periods_attributes] = [{
          started_at: started_at,
          stopped_at: existing_rides.maximum(:stopped_at)
        }]

        if target_parameter_group_name.present?
          options[:group_parameters_attributes] = target_options.map{ |t| { reference_name:  target_parameter_group_name, targets_attributes: [t] }}
        else
          options[:targets_attributes] = target_options
        end

        options
      end

      private

        def working_zone
          @working_zone ||= Rides::ComputeWorkingZone.call(rides: existing_rides)
        end

        def existing_rides
          @existing_rides ||= Ride.linkable_to_intervention.where(id: @ride_ids)
        end

        def started_at
          existing_rides.minimum(:started_at)
        end

        def main_equipment
          existing_rides.first.ride_set.equipments.find_by(nature: 'main')
        end

        def target_parameter
          procedure = Procedo::Procedure.find(@procedure_name)
          return nil if procedure.nil?

          procedure.parameters_of_type(:target, true).first
        end

        def matching_targets
          ap_ids = ActivityProduction.at(started_at).pluck(:id)
          target_klass.where(activity_production_id: ap_ids).shape_intersecting(working_zone)
        end

        def target_klass
          return @target_class if @target_class.present?

          case target_parameter.name
          when :land_parcel then LandParcel
          when :plant       then Plant
          when :cultivation then LandParcel
          else nil
          end
        end

        def target_parameter_group_name
          if target_parameter.group.name != :root_
            target_parameter.group.name
          else
            ""
          end
        end

        def compute_target_working_zone(target_shape)
          computed_working_zones = Charta.new_geometry(target_shape.intersection(working_zone))
          if computed_working_zones.instance_of?(Charta::Polygon)
            computed_working_zones.to_json_feature.with_indifferent_access
          else
            computed_working_zones.to_json_feature_collection.with_indifferent_access
          end
        end

    end
  end
end
