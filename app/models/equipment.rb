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

class Equipment < Matter
  include Attachable
  has_many :components, class_name: 'ProductNatureVariantComponent', through: :variant
  has_many :part_replacements, class_name: 'InterventionInput', foreign_key: :assembly_id
  refers_to :variety, scope: :equipment

  def tractor?
    variety == :tractor
  end

  def self_prepelled_equipment?
    variety == :self_prepelled_equipment
  end

  ##################################################
  ### Statuses #####################################

  def status
    return :stop if dead_at?
    return :caution if issues.where(state: :opened).any?
    :go
  end

  def wear_status(component = nil)
    if component.nil?
      # To take into account the tear&wear of the components.
      comp_status = variant.components.map { |c| wear_status(c) }

      # To take into account the tear&wear of the equipment itself.
      progresses = [lifespan_progress, working_lifespan_progress]
      worn_out = progresses.any? { |prog| prog >= 1 }
      almost_worn_out = progresses.any? { |prog| prog >= 0.85 }

      return :stop if comp_status.include?(:stop) || worn_out
      return :caution if comp_status.include?(:caution) || almost_worn_out
      return :go
    end

    # If we're only working on a single component.
    life_progress = lifespan_progress_of(component)
    work_progress = working_lifespan_progress_of(component)
    progresses = [life_progress, work_progress]
    return :stop if progresses.any? { |prog| prog >= 1 }
    return :caution if progresses.any? { |prog| prog >= 0.85 }
    :go
  end

  ##################################################
  ### Total lifespans values fetched from variant ##

  def total_lifespan
    variant.lifespan if has_indicator?(:lifespan)
  end

  def total_working_lifespan
    variant.working_lifespan if has_indicator?(:working_lifespan)
  end

  ##################################################
  ### Used up lifespan #############################

  def current_life
    (Time.zone.today - born_at.to_date).in(:day)
  end

  def current_work_life
    working_duration.in(:day)
  end

  ##################################################
  ### Remaining lifespans (total - gone) ###########

  def remaining_lifespan
    return nil unless total_lifespan
    total_lifespan - current_life
  end

  def remaining_working_lifespan
    return nil unless total_working_lifespan
    total_working_lifespan - current_work_life
  end

  ##################################################
  ### Lifespan progress in [0-1] and percents ######

  #### [0 - 1]

  def lifespan_progress
    return 0 unless current_life && total_lifespan
    current_life / total_lifespan
  end

  def working_lifespan_progress
    return 0 unless current_work_life && total_working_lifespan
    current_work_life / total_working_lifespan
  end

  #### [0 - 100%]

  def lifespan_progress_percent
    lifespan_progress * 100
  end

  def working_lifespan_progress_percent
    working_lifespan_progress * 100
  end

  ##################################################
  ### Work duration ################################

  ### Return working duration using the appropriate calculation.
  # Either calculates from daily_average_working_time or from
  # the time spent in interventions.
  def working_duration(since = nil)
    start = since || born_at
    work_duration = working_duration_from_average(since: start)
    work_duration ||= working_duration_from_interventions(since: start)
    work_duration.to_f.in_second
  end

  ### Returns working duration as the sum of the time spent
  # working in interventions.
  def working_duration_from_interventions(options = {})
    role = options[:as] || :tool
    periods = InterventionWorkingPeriod.with_intervention_parameter(role, self)
    periods = periods.where('started_at >= ?', options[:since]) if options[:since]
    periods = periods.of_campaign(options[:campaign]) if options[:campaign]
    periods.sum(:duration).in_second
  end

  ### Returns working duration as a product of the average work
  # time per day and the number of days worked.
  def working_duration_from_average(options = {})
    return nil unless has_indicator?(:daily_average_working_time)
    duration = (Time.zone.today - options[:since].to_date)
    average = variant.daily_average_working_time
    (average * duration.in_day).in_second
  end

  #######################################################
  ### Components ########################################

  ##################################################
  ###### Replacements ##############################

  # Returns the list of replacements
  def replacements_of(component)
    raise ArgumentError, 'Incompatible component' unless component.product_nature_variant == variant
    part_replacements.where(component: component.self_and_parents)
  end

  def replaced_at(component, since = nil)
    replacement = last_replacement(component)
    return replacement.intervention.stopped_at if replacement
    since
  end

  def last_replacement(component)
    replacements_of(component).joins(:intervention).order('interventions.stopped_at DESC').first
  end

  ##################################################
  ###### Total lifespans values ####################

  def total_lifespan_of(component)
    comp_variant = component.part_product_nature_variant
    return nil unless comp_variant && comp_variant.has_indicator?(:lifespan)
    comp_variant.lifespan
  end

  def total_working_lifespan_of(component)
    comp_variant = component.part_product_nature_variant
    return nil unless comp_variant && comp_variant.has_indicator?(:working_lifespan)
    comp_variant.working_lifespan
  end

  ##################################################
  ###### Used up lifespan ##########################

  def current_life_of(component)
    (Time.zone.now - replaced_at(component, born_at)).to_f.in_second
  end

  def current_work_life_of(component)
    working_duration(replaced_at(component, born_at)).to_f.in_second
  end

  ##################################################
  ######### Remaining lifespan values ##############

  def remaining_lifespan_of(component)
    return nil unless total_lifespan_of(component)
    total_lifespan_of(component) - current_life_of(component)
  end

  def remaining_working_lifespan_life_of(component)
    return nil unless total_working_lifespan_of(component)
    total_working_life_of(component) - current_work_life_of(component)
  end

  ##################################################
  ###### Lifespan progress in [0-1] and percents ###

  ####### [0 - 1]

  def lifespan_progress_of(component)
    return 0 unless current_life_of(component) && total_lifespan_of(component)
    current_life_of(component) / total_lifespan_of(component)
  end

  def working_lifespan_progress_of(component)
    return 0 unless current_work_life_of(component) && total_working_lifespan_of(component)
    current_work_life_of(component) / total_working_lifespan_of(component)
  end

  ####### [0 - 100%]

  def lifespan_progress_percent
    lifespan_progress_of(component) * 100
  end

  def working_lifespan_progress_percent
    working_lifespan_progress_of(component) * 100
  end

  #######################################################
  ### Notifications #####################################

  ##################################################
  ###### Equipment #################################

  def alert_life
    User.notify_administrators(
      :equipment_is_at_end_of_life,
      interpolations(remaining_lifespan),
      target: self,
      level: :warning
    )
  end

  def alert_work
    User.notify_administrators(
      :equipment_is_worn_out,
      interpolations(remaining_working_lifespan),
      target: self,
      level: :warning
    )
  end

  ##################################################
  ###### Component #################################

  def alert_component_life(component)
    User.notify_administrators(
      :equipment_component_is_at_end_of_life,
      interpolations_for(component, remaining_lifespan_of(component)),
      target: self,
      level: :warning
    )
  end

  def alert_component_work(component)
    User.notify_administrators(
      :equipment_component_is_worn_out,
      interpolations_for(component, remaining_working_lifespan_of(component)),
      target: self,
      level: :warning
    )
  end

  protected

  def interpolations(lifespan)
    {
      name: name,
      remaining_time: lifespan.in(:hour).round(2).l(precision: 0)
    }
  end

  def interpolations_for(component, lifespan)
    {
      equipment_name: name,
      component_name: component.name,
      remaining_time: lifespan.in(:hour).round(2).l(precision: 0)
    }
  end
end
