# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: intervention_participations
#
#  created_at        :datetime         not null
#  creator_id        :integer
#  id                :integer          not null, primary key
#  intervention_id   :integer
#  lock_version      :integer          default(0), not null
#  procedure_name    :string
#  product_id        :integer
#  request_compliant :boolean          default(FALSE), not null
#  state             :string
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class InterventionParticipation < Ekylibre::Record::Base
  enumerize :state, in: %i[in_progress done validated]
  enumerize :procedure_name, in: Procedo.procedure_names, i18n_scope: ['procedures']
  belongs_to :intervention
  belongs_to :product

  has_many :working_periods, class_name: 'InterventionWorkingPeriod',
                             inverse_of: :intervention_participation, dependent: :destroy
  has_many :crumbs, dependent: :destroy

  accepts_nested_attributes_for :working_periods

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :request_compliant, inclusion: { in: [true, false] }
  # ]VALIDATORS]
  validates :product, presence: true
  validates :intervention, uniqueness: { scope: [:product_id] }, unless: -> { intervention.blank? || intervention.new_record? }
  validates :state, presence: true

  scope :unprompted, -> { where(intervention: nil) }

  scope :at, lambda { |at|
    where(arel_table[:created_at].lteq(at))
  }

  scope :on, lambda { |on|
    where(arel_table[:created_at].lteq(on.to_time.end_of_day))
  }

  scope :of_intervention, lambda { |intervention|
    where(intervention_id: intervention)
  }

  scope :of_product, lambda { |product_id|
    where(product_id: product_id)
  }

  scope :sum_periods, lambda { |product_id, nature|
    InterventionParticipation.where(product_id: product_id, nature: nature)
  }

  scope :of_actor, ->(actor) { where(product_id: actor.id) }

  before_save do
    if intervention.present?
      intervention.update_state(id => state)
      intervention.update_compliance(id => request_compliant)
    end
  end

  # Data are metrics and in meter and square meter
  DEFAULT_ACCURACY = 3
  DEFAULT_ACCURACY_AREA = (((DEFAULT_ACCURACY * 0.5)**2) * Math::PI).freeze

  def human_name
    intervention ? intervention.name : procedure_name ? I18n.t(procedure_name, scope: :procedures) : nil
  end

  def sum_periods_of_nature(nature)
    working_periods.where(nature: nature).sum(:duration)
  end

  def has_period_with_nature?(nature: nil)
    !working_periods.where(nature: nature).empty?
  end

  def qualified_human_name
    return if human_name.nil? || product.name.nil?
    working_periods.empty? ? "#{human_name} (#{product.name})" : "#{:intervention_at.tl(intervention: human_name, at: working_periods.minimum(:started_at).l)} (#{product.name})"
  end

  def convert!(options = {})
    intervention = nil
    Ekylibre::Record::Base.transaction do
      options[:procedure_name] ||= procedure_name
      procedure = Procedo.find(options[:procedure_name])

      # preparing attributes for Intervention#create!
      attributes = {}
      attributes[:procedure_name] = procedure.name

      # Working periods
      attributes[:working_periods_attributes] = working_periods.collect do |wp|
        s = wp.started_at.round_off(1.minute)
        f = wp.stopped_at.round_off(1.minute)
        next if s == f
        {
          started_at: s,
          stopped_at: f
        }
      end.compact.uniq.inject([]) do |obj, dates|
        if !obj.empty? && obj.last[:stopped_at] == dates[:started_at]
          obj.last[:stopped_at] = dates[:stopped_at]
          obj
        else
          obj << dates
        end
      end
      # Parameters
      options[:working_width] ||= 6
      attributes = assign_parameters(procedure, attributes, options.slice(:working_width))

      # Create intervention
      intervention = Intervention.create!(attributes)
      self.intervention = intervention
      save!
    end
    intervention
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
            targets = Product.shape_covering(zone, 0) if targets.empty?
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
          targets = Product.shape_covering(zone, 0) if targets.empty?
          targets = targets.of_expression(parameter.filter) if parameter.filter.present?
          targets.each do |target|
            intersection = zone.intersection(target.shape.to_rgeo)
            next unless intersection.area.in_square_meter > DEFAULT_ACCURACY.in_square_meter
            attributes[key] << {
              reference_name: parameter.name,
              # working_zone: target.shape,
              working_zone: Charta.new_geometry(intersection).convert_to(:multi_polygon),
              product_id: target.id
            }
          end
        elsif product && parameter.doer?
          if parameter.filter.blank? || (parameter.filter && product.of_expression(parameter.filter))
            attributes[key] << {
              reference_name: parameter.name,
              product_id: product.id
            }
          end
        end
      end
    end
    attributes
  end

  def unconverted_crumbs
    return [] unless crumbs.any?
    start_read_at = crumbs.order(read_at: :asc).first.read_at.utc
    stop_read_at = crumbs.order(read_at: :asc).last.read_at.utc

    start = crumbs.where(nature: :start).order(read_at: :desc).first
    stop = crumbs.where(nature: :stop).order(read_at: :desc).first

    # if custom start crumb or stop_crumb
    start_read_at = start.read_at.utc if start
    stop_read_at = stop.read_at.utc if stop && stop.read_at >= start.read_at
    crumbs.where(read_at: start_read_at..stop_read_at).order(read_at: :asc)
  end
end
