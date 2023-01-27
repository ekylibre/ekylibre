# frozen_string_literal: true

class InterventionDecorator < Draper::Decorator
  delegate_all

  def land_parcels_datas(*args)
    options = args.extract_options!
    contrasted_color_callback = options[:contrasted_color_callback]

    land_parcels = []

    object.targets.find_each do |target|
      product = target.product

      next unless product

      datas = {}
      datas[:color] = target.product.activity.color if product.activity

      if activity_production = ActivityProduction.find_by(support: product)
        datas[:color] = activity_production.activity.color

        if activity_production.cultivable_zone
          datas[:name] = activity_production.cultivable_zone.work_number
        end
      end

      datas[:color] ||= '#777777'
      datas[:name] ||= product.work_number.blank? ? product.name : product.work_number

      datas[:text_color] = contrasted_color_callback.call(datas[:color]) unless contrasted_color_callback.nil?

      land_parcels << datas
    end

    land_parcels
  end

  def planned_by
    name = if object.request?
             object.creator&.full_name
           elsif object.request_intervention.present?
             object.request_intervention.creator&.full_name
           end
    if name.present?
      add_actionner_name(:planned_by, name)
    end
  end

  def validated_by
    if object.validated?
      name = object.validator&.full_name
      add_actionner_name(:validated_by, name) if name.present?
    end
  end

  def add_actionner_name(title, name)
    h.content_tag(:div, nil, class: 'info') do
      h.concat(h.content_tag(:span, title.tl, class: :title))
      h.concat(h.content_tag(:span, name, class: :value))
    end
  end

  def sum_working_zone_area_of_product(_product)
    parameters = object.targets unless planting?
    parameters = object.outputs if planting?

    parameters.map do |parameter|
      return parameter.working_zone_area unless planting?
      return parameter.product.net_surface_area if planting?
    end.sum.in(:hectare).round(2)
  end

  def planting?
    object.procedure.of_category?(:planting)
  end

  def harvesting?
    object.procedure.of_category?(:harvesting)
  end

  def sum_targets_working_zone_area
    object
      .targets
      .map(&:working_zone_area)
      .sum
      .in(:hectare)
      .round(2)
  end

  def sum_outputs_working_zone_area
    object
      .outputs
      .map(&:working_zone_area)
      .sum
      .in(:hectare)
      .round(2)
  end

  def sum_products_working_zone_area(product)
    object
      .targets
      .of_actor(product)
      .map(&:working_zone_area)
      .sum
  end

  def sum_outputs_working_zone_area_of_product(product)
    object
      .outputs
      .of_actor(product)
      .to_a
      .flatten
      .map(&:product)
      .map(&:net_surface_area)
      .sum
  end

  def sum_activity_production_working_zone_area(activity_production)
    object
      .targets
      .of_activity_production(activity_production)
      .map(&:working_zone_area)
      .sum
  end

  def sum_outputs_working_zone_area_of_activity_production(activity_production)
    object
      .outputs
      .of_activity_production(activity_production)
      .flatten
      .map(&:product)
      .map(&:net_surface_area)
      .sum
  end

  def many_targets?
    object.targets.count > 1
  end

  def global_costs
    object
      .costing
      .decorate
      .to_h
  end

  def human_global_costs
    object
      .costing
      .decorate
      .to_human_h
  end

  def inputs_cost
    parameter_cost(object.inputs)
  end

  def human_inputs_cost
    human_parameter_cost(inputs_cost)
  end

  def doers_cost
    parameter_cost(object.doers)
  end

  def human_doers_cost
    human_parameter_cost(doers_cost)
  end

  def tools_cost
    parameter_cost(object.tools)
  end

  def human_tools_cost
    human_parameter_cost(tools_cost)
  end

  def human_receptions_cost
    object
      .receptions_cost
      .to_f
      .round(2)
  end

  # This method enables to get some infos of parameters of an intervention before it is saved : we have to iterate over each association name instead of 'parameters' association
  def parameters_infos
    parameters_infos = []
    %w[targets inputs outputs tools doers].each do |param_name|
      next if object.send(param_name).empty?

      param_references = object.send(param_name).map { |param| { reference_name: param.reference_name, type: param_name } }
      parameters_infos << param_references
    end
    parameters_infos.flatten
  end

  def build_invalid_parameter(parameter)
    if parameter[:has_group_parameter]
      group_parameters.first.send(parameter[:type]).build(reference_name: parameter[:reference_name])
    else
      send(parameter[:type]).build(reference_name: parameter[:reference_name])
    end
  end
  private

    def parameter_cost(parameters)
      parameters
        .map(&:cost)
        .compact
        .sum
    end

    def human_parameter_cost(cost)
      cost
        .to_f
        .round(2)
    end
end
