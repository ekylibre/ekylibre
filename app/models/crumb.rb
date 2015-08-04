# coding: utf-8
# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
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
#
# == Table: crumbs
#
#  accuracy             :decimal(19, 4)   not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  device_uid           :string           not null
#  geolocation          :geometry({:srid=>4326, :type=>"point"}) not null
#  id                   :integer          not null, primary key
#  intervention_cast_id :integer
#  lock_version         :integer          default(0), not null
#  metadata             :text
#  nature               :string           not null
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
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :read_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :accuracy, allow_nil: true
  validates_presence_of :accuracy, :device_uid, :geolocation, :nature, :read_at
  # ]VALIDATORS]
  serialize :metadata, Hash

  scope :after,   ->(at) { where(arel_table[:read_at].gt(at)) }
  scope :before,  ->(at) { where(arel_table[:read_at].lt(at)) }
  scope :unconverted, -> { where(intervention_cast_id: nil) }

  # returns all crumbs for a given day. Default: the current day
  # TODO: remove this and replace by something like #start_day_between or #at
  scope :of_date, lambda{|start_date = Time.now.midnight|
    where(read_at: start_date.midnight..start_date.end_of_day)
  }

  before_validation do
    if self.start?
      if previous && original = previous.siblings.find_by(nature: :start)
        self.metadata ||= original.metadata
        self.metadata['procedure_nature'] ||= original.metadata['procedure_nature']
      else
        self.metadata ||= {}
        self.metadata['procedure_nature'] ||= 'administrative_task'
      end
    end
  end

  after_destroy do
    intervention_path.delete_all if self.start?
  end

  after_update do
    if self.start? && previous = self.previous
      previous.update_column(:nature, :stop) unless previous.stop?
    end
  end

  # Returns the previous crumb if it exists
  def previous
    siblings.before(read_at).reorder(read_at: :desc).first
  end

  # Returns the next crumb if it exists
  def following
    siblings.after(read_at).reorder(read_at: :asc).first
  end

  # Returns siblings of the crumbs (same user, same device)
  def siblings
    Crumb.where(user_id: user_id, device_uid: device_uid).order(read_at: :asc)
  end

  class << self
    # Returns all products whose shape contains the given crumbs or any crumb if no crumb is given
    # options:  no_content: excludes contents. Default: false
    # TODO: when refactoring, move this method to Product model, as Product#of_crumbs(*crumbs)
    def products(*crumbs)
      options = crumbs.extract_options!
      crumbs.flatten!
      raw_products = Product.distinct.joins(:readings)
                     .joins("INNER JOIN crumbs ON (indicator_datatype = 'geometry' AND ST_Contains(ST_CollectionExtract(product_readings.geometry_value, 3), crumbs.geolocation))")
                     .where(crumbs.any? ? ['crumbs.id IN (?)', crumbs.map(&:id)] : 'crumbs.id IS NOT NULL')
      contents = []
      contents = raw_products.map(&:contents) unless options[:no_contents]
      raw_products.concat(contents).flatten.uniq
    end

    # returns all production supports whose storage shape contains the given crumbs
    # ==== Parameters
    #     - crumbs: an array of crumbs
    # ==== Options
    #     - campaigns: one or several campaigns for which production supports are looked for. Default: current campaigns.
    #       Accepts the same parameters as ProductionSupport.of_campaign since it actually calls this method.
    # TODO: when refactoring, move this method to ProductionSupport model, as ProductionSupport#of_crumbs(crumbs = [], options = {})
    def production_supports(*crumbs)
      options = crumbs.extract_options!
      options[:campaigns] ||= Campaign.currents
      ProductionSupport.of_campaign(options[:campaigns]).distinct
        .joins(:storage)
        .where('products.id IN (?)', Crumb.products(*crumbs, no_contents: true).map(&:id))
    end

    # Returns all crumbs, grouped by interventions paths, for a given user.
    # The result is an array of interventions paths.
    # An intervention path is an array of crumbs, for a user, ordered by read_at,
    # between a start crumb and a stop crumb.
    # if data is inconsistent (e.g. no "stop" crumb corresponding to a "start" crumb)
    # the buffer stores crumbs until the next "start" crumb in the chronological order,
    # and the result receives what is found, whatever the crumbs table content, since the user may always
    # requalify crumbs manually.
    # TODO : put this into User model
    def interventions_paths(user)
      ActiveSupport::Deprecation.warn('Use User#interventions_paths instead')
      user.interventions_paths
    end

    # # returns all the dates for which a given user has pushed crumbs
    # def interventions_dates(user)
    #   Crumb.where(nature: 'start').where(user_id: user.id).pluck(:read_at).map(&:midnight).uniq
    # end
  end

  # returns all the crumbs corresponding to the same intervention as the current crumb, i.e. the nearest start crumb including itself,
  # the nearest stop crumb including itself, and all the crumbs in between including the crumb itself.
  def intervention_path
    start_read_at = read_at.utc
    unless start?
      start = siblings.where(nature: :start)
              .where('read_at <= ?', start_read_at)
              .order(read_at: :desc)
              .first
      start_read_at = start.read_at.utc if start
    end
    stop_read_at = read_at.utc
    unless stop?
      stop = siblings.where(nature: :stop)
             .where('read_at >= ?', stop_read_at)
             .order(nature: :desc, read_at: :asc)
             .first
      stop_read_at  = stop.read_at.utc if stop
    end
    CrumbSet.new(siblings.where(read_at: start_read_at..stop_read_at).order(read_at: :asc))
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
      options[:actors_ids] << worker.id if user && worker
      actors = Crumb.products(intervention_path.to_a).concat(Product.find(options[:actors_ids])).compact.uniq
      unless options[:support_id] ||= Crumb.production_supports(intervention_path.where(nature: :hard_start)).pluck(:id).first
        fail StandardError, :need_a_production_support.tn
      end
      support = ProductionSupport.find(options[:support_id])
      options[:procedure_name] ||= Intervention.match(actors, options).first[0].name
      procedure = Procedo[options[:procedure_name]]

      # preparing attributes for Intervention#create!
      attributes = {}
      attributes[:started_at] = intervention_path.started_at
      attributes[:stopped_at] = intervention_path.stopped_at
      attributes[:reference_name] = procedure.name
      # attributes[:production] = support.production
      attributes[:production_support] = support
      intervention = Intervention.create!(attributes)

      # creates casts
      # adds actors
      procedure.matching_variables_for(actors).each do |variable, actor|
        attributes = {}
        attributes[:actor] = actor
        attributes[:reference_name] = variable.name
        cast = intervention.add_cast!(attributes)
        if worker && actor == worker
          intervention_path.update_all(intervention_cast_id: cast.id)
        end
      end

      # adds empty casts for unknown actors
      for variable in procedure.variables.values
        unless intervention.casts.map(&:reference_name).include? variable.name.to_s
          intervention.add_cast!(reference_name: variable.name)
        end
      end
    end
    intervention
  end

  # Returns possible procedures matching a crumb and its corresponding intervention path
  # Options: the same as Intervention#match
  def possible_procedures_matching(options = {})
    Intervention.match(Crumb.products(intervention_path.to_a), options).map { |procedure, *| procedure }
  end
end
