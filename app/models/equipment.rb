# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  address_id            :integer
#  born_at               :datetime
#  category_id           :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  custom_fields         :jsonb
#  dead_at               :datetime
#  default_storage_id    :integer
#  derivative_of         :string
#  description           :text
#  fixed_asset_id        :integer
#  id                    :integer          not null, primary key
#  identification_number :string
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_geolocation   :geometry({:srid=>4326, :type=>"point"})
#  initial_mother_id     :integer
#  initial_movement_id   :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :geometry({:srid=>4326, :type=>"multi_polygon"})
#  lock_version          :integer          default(0), not null
#  name                  :string           not null
#  nature_id             :integer          not null
#  number                :string           not null
#  parent_id             :integer
#  person_id             :integer
#  picture_content_type  :string
#  picture_file_name     :string
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  tracking_id           :integer
#  type                  :string
#  updated_at            :datetime         not null
#  updater_id            :integer
#  uuid                  :uuid
#  variant_id            :integer          not null
#  variety               :string           not null
#  work_number           :string
#

class Equipment < Matter
  include Attachable
  refers_to :variety, scope: :equipment

  ##################################################
  ### Statuses #####################################

  def status
    return :stop if dead_at?
    return :caution if issues.where(state: :opened).any?
    return :go
  end

  def wear_status(component = nil)
    if component.nil?
      comp_status = variant.components.map { |c| wear_status(c) }
      return :stop if comp_status.include?(:stop)
      return :caution if comp_status.include?(:caution)
      return :go
    end

    work_progress = working_life_progress_of(component)
    life_progress = total_life_progress_of(component)
    progresses = [work_progress, life_progress]
    return :stop if progresses.any? { |prog| prog >= 1 }
    return :caution if progresses.any? { |prog| prog >= 0.95 }
    return :go
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
  ### Remaining lifespans (total - gone) ###########

  def remaining_lifespan
    return nil unless total_lifespan
    return (total_lifespan - (Time.zone.today - born_at.to_date).in(:day))
  end

  def remaining_working_lifespan
    return nil unless total_working_lifespan
    return total_working_lifespan - working_duration.in(:day)
  end


  ##################################################
  ### Lifespan progress in [0-1] and percents ######

  #### [0 - 1]

  def lifespan_progress
    1 - (remaining_lifespan || 1) / (total_lifespan || 1)
  end

  def working_lifespan_progress
    1 - (remaining_working_lifespan || 1) / (total_working_lifespan || 1)
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
    return work_duration.to_f.in_second
  end

  ### Returns working duration as the sum of the time spent
  # working in interventions.
  def working_duration_from_interventions(options = {})
    role = options[:as] || :tool
    periods = InterventionWorkingPeriod.with_intervention_parameter(role, self)
    periods = periods.where('started_at >= ?', options[:since])  if options[:since]
    periods = periods.of_campaign(options[:campaign]) if options[:campaign]
    periods.sum(:duration).in_second
  end

  ### Returns working duration as a product of the average work
  # time per day and the number of days worked.
  def working_duration_from_average(options = {})
    return nil unless has_indicator?(:daily_average_working_time)
    duration = (Time.zone.today - options[:since].to_date)
    average = variant.daily_average_working_time
    return (average * duration.in_day).in_second
  end


  #######################################################
  ### Components ########################################

  ##################################################
  ###### Replacements ##############################

  def replaced_at(component, since = nil)
    replacement = last_replacement(component)
    return replacement.intervention.stopped_at if replacement
    return since
  end

  def last_replacement(component)
    replacements = ProductPartReplacement.where(component: component.self_and_parents).joins(:intervention)
    replacements.order('interventions.stopped_at DESC').first
  end

  ##################################################
  ###### Total lifespans values ####################

  def working_life_of(component)
    working_duration(replaced_at(component, born_at)).to_f.in_second
  end

  def total_life_of(component)
    (Time.zone.now - replaced_at(component, born_at)).to_f.in_second
  end

  ##################################################
  ###### Lifespan progress in [0-1] and percents ###

  ####### [0 - 1]

  def working_life_progress_of(component)
    comp_variant = component.product_nature_variant
    return 0 unless comp_variant && comp_variant.has_indicator?(:working_lifespan)
    working_life_of(component).to_f(:second) / component.product_nature_variant.working_lifespan.to_f(:second)
  end

  def total_life_progress_of(component)
    return 0 if !component.product_nature_variant || !component.product_nature_variant.has_indicator?(:lifespan)
    total_life_of(component).to_f(:second) / component.product_nature_variant.lifespan.to_f(:second)
  end

  ####### [0 - 100%]

  def total_life_progress_percent_of(component)
    total_life_progress_of(component) * 100
  end

  def working_life_progress_percent_of(component)
    total_life_progress_of(component) * 100
  end
end
