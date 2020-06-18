# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: products
#
#  activity_production_id       :integer
#  address_id                   :integer
#  birth_date_completeness      :string
#  birth_farm_number            :string
#  born_at                      :datetime
#  category_id                  :integer          not null
#  codes                        :jsonb
#  country                      :string
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  custom_fields                :jsonb
#  dead_at                      :datetime
#  default_storage_id           :integer
#  derivative_of                :string
#  description                  :text
#  end_of_life_reason           :string
#  father_country               :string
#  father_identification_number :string
#  father_variety               :string
#  filiation_status             :string
#  first_calving_on             :datetime
#  fixed_asset_id               :integer
#  id                           :integer          not null, primary key
#  identification_number        :string
#  initial_born_at              :datetime
#  initial_container_id         :integer
#  initial_dead_at              :datetime
#  initial_enjoyer_id           :integer
#  initial_father_id            :integer
#  initial_geolocation          :geometry({:srid=>4326, :type=>"st_point"})
#  initial_mother_id            :integer
#  initial_movement_id          :integer
#  initial_owner_id             :integer
#  initial_population           :decimal(19, 4)   default(0.0)
#  initial_shape                :geometry({:srid=>4326, :type=>"multi_polygon"})
#  lock_version                 :integer          default(0), not null
#  member_variant_id            :integer
#  mother_country               :string
#  mother_identification_number :string
#  mother_variety               :string
#  name                         :string           not null
#  nature_id                    :integer          not null
#  number                       :string           not null
#  origin_country               :string
#  origin_identification_number :string
#  originator_id                :integer
#  parent_id                    :integer
#  person_id                    :integer
#  picture_content_type         :string
#  picture_file_name            :string
#  picture_file_size            :integer
#  picture_updated_at           :datetime
#  reading_cache                :jsonb            default("{}")
#  team_id                      :integer
#  tracking_id                  :integer
#  type                         :string
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  uuid                         :uuid
#  variant_id                   :integer          not null
#  variety                      :string           not null
#  work_number                  :string
#
class Plant < Bioproduct
  has_many :plant_countings
  refers_to :variety, scope: :plant

  has_shape

  # Return all Plant object who is alive in the given campaigns
  scope :of_campaign, lambda { |campaign|
    unless campaign.is_a?(Campaign)
      raise ArgumentError, "Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}"
    end
    started_at = Date.new(campaign.harvest_year, 0o1, 0o1)
    stopped_at = Date.new(campaign.harvest_year, 12, 31)
    where('born_at <= ? AND (dead_at IS NULL OR dead_at <= ?)', stopped_at, stopped_at)
  }

  after_validation do
    # Compute population
    if initial_shape && nature
      if variable_indicators_list.include?(:net_surface_area)
        read!(:net_surface_area, initial_shape_area, at: initial_born_at)
      end
      if frozen_indicators_list.include?(:net_surface_area) && variant.net_surface_area.nonzero?
        self.initial_population = initial_shape_area / variant.net_surface_area
      end
    end
  end

  after_create do
    link_to_production
  end

  def status
    if dead_at?
      :stop
    elsif issues.any?
      (issues.where(state: :opened).any? ? :caution : :go)
    else
      :go
    end
  end

  def last_sowing
    Intervention
      .real
      .where(
        procedure_name: :sowing,
        id: InterventionOutput
          .where(product: self)
          .select(:intervention_id)
      )
      .order(started_at: :desc)
      .first
  end

  def sower
    last_sowing && last_sowing.parameters.select { |eq| eq.reference_name.to_sym == :sower }.first
  end

  def ready_to_harvest?
    analysis = analyses.where(nature: 'plant_analysis').reorder(sampled_at: :desc).first
    return false unless analysis
    item = analysis.items.find_by(indicator_name: 'ready_to_harvest')
    return false unless item
    item.value
  end

  # INSPECTIONS RELATED

  def stock_in_ground_by_calibration_series(dimension, natures)
    find_calib = ->(i, nature) { i.calibrations.find_by(nature: nature) }
    marketable = ->(calib) { calib.marketable_quantity(dimension).in(calib.user_quantity_unit(dimension)) }
    name = ->(nature) { nature.name }

    curves(natures, find_calib, marketable, name)
  end

  def disease_deformity_series(dimension)
    categories = ActivityInspectionPointNature.unmarketable_categories
    cat_percentage = ->(i, category) { i.points_percentage(dimension, category) }
    nothing = ->(percentage) { percentage }

    curves(categories, cat_percentage, nothing, nothing)
  end

  # Returns unique varieties
  def self.unique_varieties
    pluck(:variety)
      .uniq
      .map { |variety| Nomen::Variety.find(variety) }
  end

  private

  # FIXME: Why this code is here??? Not linked to Plant
  def curves(collection, set_first_val, get_value, get_name, round = 2)
    hashes = inspections.reorder(:sampled_at).map do |intervention|
      pairs = collection.map do |grouping_crit|
        pre_val = set_first_val.call(intervention, grouping_crit)
        value = (pre_val ? get_value.call(pre_val) : 0).to_s.to_f
        value = value.round(round) if round
        [get_name.call(grouping_crit), value]
      end
      Rails.logger.info pairs.inspect.red
      pairs_to_hash(pairs)
    end

    merge_all(hashes)
  end

  # FIXME: Why this code is here??? Not linked to Plant
  # [ {[1]}, {[2]}, {[3]} ] => { [1,2], [3] }
  def merge_all(hashes)
    hashes.reduce do |final, caliber_hash|
      final.merge(caliber_hash) { |_k, old_val, new_val| old_val + new_val }
    end
  end

  # FIXME: Why this code is here??? Not linked to Plant
  # [[1, 2], [1, 3], [2, 3]] => { 1: [2, 3], 2: [3] }
  def pairs_to_hash(array_of_pairs)
    array_of_pairs
      .group_by(&:first)
      .map { |crit, g_pairs| [crit, g_pairs.map(&:last)] }
      .to_h
  end

  def link_to_production
    outputs = InterventionOutput.where(product: self, reference_name: 'plant')
    unless outputs.empty?
      ap = outputs.first.intervention.targets.where(reference_name: 'land_parcel').first.product.activity_production
      update(activity_production: ap)
    end
  end
end
