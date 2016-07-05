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

  def net_mass_in_unit
    (net_mass_value || 0).in(grading_net_mass_unit)
  end

  def items_count_in_unit
    (items_count || 0).in(Nomen::Unit.find(:unity))
  end

  def minimal_size
    (minimal_size_value || 0).in(grading_sizes_unit)
  end

  def maximal_size
    (maximal_size_value || 0).in(grading_sizes_unit)
  end

  def total_net_mass
    (net_mass_in_unit * (product_net_surface_area.to_d(:square_meter) / sampling_area.to_d(:square_meter))).round(0)
  end

  def total_items_count
    (items_count_in_unit * (product_net_surface_area.to_d(:square_meter) / sampling_area.to_d(:square_meter))).round(0)
  end

  def find_item_unit(value)
    if value <= 1
      closest_round = 0
    else
      closest_round = 10 ** Math.log(value, 10).floor
    end
    units = Nomen::Unit.where(dimension: :none).select { |u| u.symbol.last == '.' }
    units.min_by { |u| (u.a - closest_round).abs }
  end

  def items_count_yield
    unit_name = "#{find_item_unit(total_items_count.to_f).name}_per_#{product_net_surface_area.unit}"
    unit_name = :unity_per_square_meter unless Nomen::Unit.find(unit_name)
    y = (items_count_in_unit.to_d(:unity) / sampling_area.to_d(:square_meter)).in(:unity_per_square_meter)
    y.in(unit_name).round(0)
  end

  def net_mass_yield
    unit_name = "#{grading_net_mass_unit.name}_per_#{product_net_surface_area.unit}"
    unit_name = :kilogram_per_hectare unless Nomen::Unit.find(unit_name)
    y = (net_mass_in_unit.to_d(:kilogram) / sampling_area.to_d(:square_meter)).in(:kilogram_per_square_meter)
    y.in(unit_name).round(0)
  end
end
