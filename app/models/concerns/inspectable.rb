module Inspectable
  extend ActiveSupport::Concern

  included do
    has_one :activity, through: :nature
    has_one :product, through: :inspection

    delegate :human_grading_net_mass_unit_name,
             :human_grading_calibre_unit_name,
             :human_grading_sizes_unit_name, to: :activity
    delegate :measure_grading_net_mass,
             :measure_grading_items_count,
             :measure_grading_sizes,
             :grading_net_mass_unit,
             :grading_sizes_unit, to: :activity
    delegate :name, to: :nature, prefix: true
    delegate :total_area,
             :sample_area,
             :quantity_unit,
             :quantity_per_area_unit,
             :default_quantity_unit,
             :default_per_area_unit,
             :default_area_unit,
             :user_quantity_unit,
             :user_per_area_unit,
             :default_quantity_unit,
             :unknown_dimension, to: :inspection
  end

  def projected_total(dimension)
    number_of_samples = (total_area / sample_area)
    (quantity_in_unit(dimension) * number_of_samples)
  end

  def quantity_yield(dimension)
    quantity = quantity_in_unit(dimension).to_d(quantity_unit(dimension))
    y = (quantity / sample_area).in(default_per_area_unit(dimension))
    y.in(quantity_per_area_unit(dimension))
  end

  ##### Primitives

  def extremum_size(type)
    raise 'Type must either be `min` or `max`' unless %w(min max).include?(type.to_s)
    value = send(:"#{type}imal_size_value")
    (value || 0).in(grading_sizes_unit)
  end

  def quantity_in_unit(dimension)
    quantity_value(dimension).in(quantity_unit(dimension))
  end

  ### Values

  # Quantities
  def quantity_value(dimension)
    return (send(:"#{dimension}_value") || 0) if respond_to?(:"#{dimension}_value")
    unknown_dimension(dimension)
  end
end
