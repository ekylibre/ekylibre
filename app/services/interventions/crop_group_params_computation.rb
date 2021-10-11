# frozen_string_literal: true

module Interventions
  # Transform crop groups id into intervention target parameters
  class CropGroupParamsComputation

    def initialize(procedure_name, crop_group_ids)
      @procedure_name = procedure_name
      @crop_group_ids = [*crop_group_ids]
    end

    def options
      options = { targets_attributes: [],
        group_parameters_attributes: [],
        labellings_attributes: [] }
      return options if target_parameter.nil?

      if matching_targets.any?
        target_options = matching_targets.map {|target| { reference_name: target_parameter.name, product_id: target.id, working_zone: target.shape }}

        if  target_parameter_group_name.present?
          options[:group_parameters_attributes] = target_options.map{ |target| { reference_name:  target_parameter_group_name, targets_attributes: [target] }}
        else
          options[:targets_attributes] = target_options
        end
      end

      options[:labellings_attributes] = labels.map { |label| { label_id: label.id } } if labels.any?

      options
    end

    # @return [Array<Crop>] rejected crops
    def rejected_crops
      @rejected_crops ||= crops.difference(matching_targets)
    end

    private
      attr_reader :procedure_name, :crop_group_ids

      def target_parameter
        procedure = Procedo::Procedure.find(procedure_name)
        return nil if procedure.nil?

        procedure.parameters_of_type(:target, true).first
      end

      def crops
        CropGroup.find(crop_group_ids).flat_map(&:crops)
      end

      def crop_groups
        CropGroup.find(crop_group_ids)
      end

      def matching_targets
        CropGroup.available_crops(crop_group_ids, target_parameter.filter)
      end

      def target_parameter_group_name
        if target_parameter.group.name != :root_
          target_parameter.group.name
        else
          ""
        end
      end

      def labels
        if target_parameter.present?
          type = target_parameter.name == :cultivation ? %w[plant land_parcel] : target_parameter.name.to_s
        end
        CropGroup.collection_labels(crop_group_ids, type)
      end
  end
end
