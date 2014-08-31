# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: crumbs
#
#  accuracy             :decimal(19, 4)   not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  geolocation          :spatial({:srid=> not null
#  id                   :integer          not null, primary key
#  intervention_cast_id :integer
#  lock_version         :integer          default(0), not null
#  metadata             :text
#  nature               :string(255)      not null
#  read_at              :datetime         not null
#  updated_at           :datetime         not null
#  updater_id           :integer
#  user_id              :integer
#

class Crumb < Ekylibre::Record::Base
  enumerize :nature, in: [:point, :start, :stop, :pause, :resume, :scan, :hard_start, :hard_stop], predicates: true
  belongs_to :user
  belongs_to :intervention_cast
  has_one :worker, through: :user
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :accuracy, allow_nil: true
  validates_length_of :nature, allow_nil: true, maximum: 255
  validates_presence_of :accuracy, :geolocation, :nature, :read_at
  #]VALIDATORS]
  serialize :metadata, Hash

  # scope :at,      lambda { |at| where(arel_table[:started_at].lteq(at).and(arel_table[:stopped_at].eq(nil).or(arel_table[:stopped_at].gt(at)))) }
  scope :after,   lambda { |at| where(arel_table[:read_at].gt(at)) }
  scope :before,  lambda { |at| where(arel_table[:read_at].lt(at)) }
  scope :unconverted, -> { where(intervention_cast_id: nil) }

  # returns all crumbs for a given day. Default: the current day
  # TODO: remove this and replace by something like #start_day_betwee or #at
  scope :of_date, lambda{|start_date = Time.now.midnight|
    where(read_at: start_date.midnight..start_date.end_of_day)
  }

  after_destroy do
    if self.start?
      self.intervention_path.delete_all
    end
  end

  before_update do
    if self.start? and previous = self.previous
      unless previous.stop?
        previous.update_column(:nature, :stop)
      end
    end
  end

  # Returns the previous crumb if it exists
  def previous
    self.siblings.before(self.read_at).reorder(read_at: :desc).first
  end

  # Returns the next crumb if it exists
  def following
    self.siblings.after(self.read_at).reorder(read_at: :asc).first
  end

  # Returns siblings of the crumbs (same user, same device)
  def siblings
    Crumb.where(user_id: self.user_id).order(read_at: :asc)
  end

  # Returns all products whose shape contains the given crumbs or any crumb if no crumb is given
  # options:  no_content: excludes contents. Default: false
  # TODO: when refactoring, move this method to Product model, as Product#of_crumbs(*crumbs)
  def self.products(*crumbs)
    crumbs.flatten!
    raw_products = Product.distinct.joins(:readings)
          .joins("INNER JOIN crumbs ON ST_CONTAINS(product_readings.geometry_value, crumbs.geolocation)")
          .where(crumbs.any? ? ["crumbs.id IN (?)", crumbs.map(&:id)] : "crumbs.id IS NOT NULL")
    contents = raw_products.map(&:contents)
    raw_products.concat(contents).flatten.uniq
  end

  # returns all production supports whose storage shape contains the given crumbs
  # ==== Parameters
  #     - crumbs: an array of crumbs
  # ==== Options
  #     - campaigns: one or several campaigns for which production supports are looked for. Default: current campaigns.
  #       Accepts the same parameters as ProductionSupport.of_campaign since it actually calls this method.
  # TODO: when refactoring, move this method to ProductionSupport model, as ProductionSupport#of_crumbs(crumbs = [], options = {})
  def self.production_supports(crumbs = [], options = {})
    options[:campaigns] ||= Campaign.currents
    ProductionSupport.of_campaign(options[:campaigns]).distinct
      .joins(:storage)
      .where("products.id IN (?)", Crumb.products(crumbs).map(&:id))
  end

  # returns all crumbs, grouped by interventions paths, for a given user.
  # The result is an array of interventions paths.
  # An intervention path is an array of crumbs, for a user, ordered by read_at,
  # between a start crumb and a stop crumb.
  # if data is inconsistent (e.g. no "stop" crumb corresponding to a "start" crumb)
  # the buffer stores crumbs until the next "start" crumb in the chronological order,
  # and the result receives what is found, whatever the crumbs table content, since the user may always
  # requalify crumbs manually.
  # TODO : put this into User model
  def self.interventions_paths(user)
    buffer = []
    result = []
    Crumb.where(user_id: user.id).order(read_at: :asc).each do |crumb|
      if buffer.present? && crumb.nature == 'start'
        result << buffer
        buffer = []
      end
      buffer << crumb
    end
    result << buffer if buffer.present?
    result
  end

  # returns all the dates for which a given user has pushed crumbs
  def self.interventions_dates(user)
    Crumb.where(nature: 'start').where(user_id: user.id).pluck(:read_at).map(&:midnight).uniq
  end

  # returns all the crumbs corresponding to the same intervention as the current crumb, i.e. the nearest start crumb including itself,
  # the nearest stop crumb including itself, and all the crumbs in between including the crumb itself.
  def intervention_path
    if nature == 'start'
      start_read_at = self.read_at.utc
    else
      start_read_at = Crumb.where(user_id: self.user_id).where(nature: :start).
                            where("read_at <= ?", self.read_at.utc).
                            order(read_at: :desc).
                            pluck(:read_at).
                            first.utc
    end
    if nature == 'stop'
      stop_read_at = self.read_at.utc
    else
      stop_read_at  = Crumb.where(user_id: self.user_id).
                            where(nature: [:point, :stop]).
                            where("read_at >= ?", self.read_at.utc).
                            order(nature: :desc, read_at: :asc).
                            pluck(:read_at).
                            first.utc
    end
    self.siblings.where(read_at: start_read_at..stop_read_at).order(read_at: :asc)
  end

  # Turns a crumb into an actual intervention and returns the created intervention if any
  # ==== Options :
  #   * General options:
  #       - support_id: the production support id for which the user wants to register an intervention.
  #         Default: the first production support matched for the hard start crumbs of the same intervention
  #         as the current crumb
  #       - procedure_name: the name of the procedure for which the user wants to register an intervention.
  #         Default: the first result matched by Intervention#match for the actors found from the crumbs of the
  #         same intervention as the current crumb.
  #   * Intervention#match related options:
  #       - actors_ids: an array of ids corresponding to products that #products method might not match
  #         but that belong to the current intervention. This array is converted into an array of products
  #         and merged with products found by Crumb#products for the current intervention before being passed
  #         to Intervention#match.
  #       - relevance, limit, history, provisional, max_arity: see Intervention#match documentation.
  def convert!(options = {})
    intervention = nil
    Ekylibre::Record::Base.transaction do
      options[:actors_ids] ||= []
      options[:actors_ids] << self.worker.id unless self.worker.nil?
      actors = Crumb.products(intervention_path).concat(Product.find(options[:actors_ids])).compact.uniq
      unless options[:support_id] ||= Crumb.production_supports(intervention_path.where(nature: :hard_start)).pluck(:id).first
        raise StandardError, "Need a production support"
      end
      support = ProductionSupport.find(options[:support_id])
      options[:procedure_name] ||= Intervention.match(actors, options).first[0].name
      procedure = Procedo[options[:procedure_name]]

      # preparing attributes for Intervention#create!
      attributes = {}
      attributes[:started_at] = intervention_path.where(nature: :start).pluck(:read_at).first
      attributes[:stopped_at] = intervention_path.where(nature: :stop).pluck(:read_at).first
      attributes[:reference_name] = procedure.name
      attributes[:production] = support.production
      attributes[:production_support] = support
      intervention = Intervention.create!(attributes)

      # creates casts
      # adds actors
      procedure.matching_variables_for(actors).each do |variable, actor|
        attributes = {}
        attributes[:actor] = actor
        attributes[:reference_name] = variable.name
        cast = intervention.add_cast!(attributes)
        if self.worker and actor == self.worker
          intervention_path.update_all(intervention_cast_id: cast.id)
        end
      end

      # adds empty casts for unknown actors
      procedure.variables.values.each do |variable|
        intervention.add_cast!(reference_name: variable.name) unless intervention.casts.map(&:reference_name).include? variable.name.to_s
      end
    end
    return intervention
  end

  # Returns possible procedures matching a crumb and its corresponding intervention path
  # Options: the same as Intervention#match
  def possible_procedures_matching(options = {})
    Intervention.match(Crumb.products(intervention_path), options).map{|procedure, *| procedure}
  end

end
