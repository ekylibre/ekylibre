module Inspectable
  extend ActiveSupport::Concern

  included do
    has_one :activity, through: :nature
    has_one :product, through: :inspection

    delegate :human_grading_net_mass_unit_name, :human_grading_calibre_unit_name,
             :human_grading_sizes_unit_name, to: :activity
    delegate :measure_grading_net_mass, :measure_grading_items_count,
             :measure_grading_sizes,
             :grading_net_mass_unit, :grading_sizes_unit, to: :activity
    delegate :name, to: :nature, prefix: true
    delegate :product_net_surface_area, :sampling_area, to: :inspection
  end

  def net_mass
    (net_mass_value || 0).in(grading_net_mass_unit)
  end

  def minimal_size
    (minimal_size_value || 0).in(grading_sizes_unit)
  end

  def maximal_size
    (maximal_size_value || 0).in(grading_sizes_unit)
  end

  def total_net_mass
    (net_mass * (product_net_surface_area.to_d(:square_meter) / sampling_area.to_d(:square_meter))).round(0)
  end

  def net_mass_yield
    unit_name = "#{grading_net_mass_unit.name}_per_#{product_net_surface_area.unit}"
    unit_name = :kilogram_per_hectare unless Nomen::Unit.find(unit_name)
    y = (net_mass.to_d(:kilogram) / sampling_area.to_d(:square_meter)).in(:kilogram_per_square_meter)
    y.in(unit_name).round(0)
  end
end
