# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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

class CrumbSet
  attr_reader :crumbs, :start, :started_at, :stopped_at, :user, :device_uid,
              :intervention_parameter, :procedure

  delegate :each, :to_a, :where, :order, :update_all, :delete_all, to: :crumbs

  # Data are metrics and in meter and square meter
  DEFAULT_ACCURACY = 3
  DEFAULT_ACCURACY_AREA = (((DEFAULT_ACCURACY * 0.5)**2) * Math::PI).freeze

  def initialize(crumbs)
    @crumbs = crumbs
    @start = @crumbs.first
    if @start
      @start.metadata ||= {}
      @procedure = Procedo.find(@start.metadata['procedure_nature'])
      unless @procedure
        Rails.logger.warn "Unknown procedure nature: #{@start.metadata['procedure_nature'].inspect}"
      end
      @started_at = @start.read_at
      @stopped_at = stop.read_at
      @stopped_at += 1 if @started_at == @stopped_at
      @user = @start.user
      @device_uid = @start.device_uid
      @intervention_parameter = @start.intervention_parameter
    else
      Rails.logger.warn 'Unknown procedure nature: No points, so no start point...'
    end
  end

  def stop
    @crumbs.last
  end

  def human_name
    :intervention_at.tl(intervention: procedure_name, at: @start.read_at.l)
  end

  def size
    @crumbs.count
  end

  def id
    "set_#{start.id}"
  end

  def casted?
    !@intervention_parameter.nil?
  end

  def procedure_name
    (@procedure ? @procedure.human_name : :unknown.tl)
  end

  def intervention
    (@intervention_parameter ? @intervention_parameter.intervention : nil)
  end

  # Turns a crumb set into an actual intervention and returns the created
  # intervention
  # ==== Options:
  # @option options [String] :procedure_name The name of the procedure for which
  #   the user wants to register an intervention.
  # @option options [String] :issue_id The ID of an issue the intervention is
  #   related to
  def convert!(options = {})
    intervention = nil
    Ekylibre::Record::Base.transaction do
      options[:procedure_name] ||= @procedure.name
      procedure = Procedo.find(options[:procedure_name])

      # preparing attributes for Intervention#create!
      attributes = {}
      attributes[:procedure_name] = procedure.name

      # Working periods
      attributes[:working_periods_attributes] = []
      attributes[:working_periods_attributes] << {
        started_at: started_at,
        stopped_at: stopped_at
      }

      # Parameters
      options[:working_width] ||= 6
      attributes = assign_parameters(procedure, attributes, options.slice(:working_width))

      # Create intervention
      intervention = Intervention.create!(attributes)
    end
    intervention
  end

  def worker
    return nil unless user
    @worker ||= user.worker
  end

  def working_zone(working_width = nil)
    working_width ||= DEFAULT_ACCURACY
    unless @working_zone && @working_width == working_width
      @working_width = working_width
      if crumbs.size > 1
        line = Charta.make_line(crumbs.order(:read_at).map(&:geolocation))
        @working_zone = line.buffer(@working_width)
      end
    end
    @working_zone
  end

  def ==(other)
    @start == other.start
  end

  protected

  def assign_parameters(group, attributes = {}, options = {})
    zone = working_zone(options[:working_width])
    group.each_parameter do |parameter|
      key = "#{parameter.reflection_name}_attributes".to_sym
      attributes[key] ||= []
      if parameter.is_a?(Procedo::Procedure::GroupParameter)
        target_parameters = parameter.parameters_of_type(:target)
        # If group contains targets directly inside, we multiply group
        if target_parameters.any?
          target_parameters.each do |target_parameter|
            targets = Product.shape_overlapping(zone)
            targets = targets.of_expression(target_parameter.filter) if target_parameter.filter.present?
            targets.each do |target|
              intersection = zone.intersection(target.shape)
              next unless intersection.area > DEFAULT_ACCURACY.in_square_meter
              attributes[key] << {
                reference_name: parameter.name,
                targets_attributes: [
                  { reference_name: target_parameter.name,
                    # working_zone: target.shape,
                    working_zone: intersection,
                    product_id: target.id }
                ]
              }
            end
          end
        else
          # Not beautiful, but will work until procedure are 2-level deep only.
          attributes[key] << assign_parameters(parameter, { reference_name: parameter.name }, options)
        end
      else
        if parameter.target?
          targets = Product.shape_overlapping(zone)
          targets = targets.of_expression(parameter.filter) if parameter.filter.present?
          targets.each do |target|
            intersection = zone.intersection(target.shape)
            next unless intersection.area > DEFAULT_ACCURACY.in_square_meter
            attributes[key] << {
              reference_name: parameter.name,
              # working_zone: target.shape,
              working_zone: intersection,
              product_id: target.id
            }
          end
        elsif worker && parameter.doer?
          if parameter.filter.blank? || (parameter.filter && worker.of_expression(parameter.filter))
            attributes[key] << {
              reference_name: parameter.name,
              product_id: worker.id
            }
          end
        end
      end
    end
    attributes
  end
end
