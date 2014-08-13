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
#  accuracy     :decimal(, )      not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  geolocation  :spatial({:srid=> not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  metadata     :text
#  nature       :string(255)      not null
#  read_at      :datetime         not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#  user_id      :integer          not null
#

class Crumb < Ekylibre::Record::Base
  enumerize :nature, in: [:point, :start, :stop, :pause, :resume, :scan, :hard_start, :hard_stop]
  belongs_to :user
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :accuracy, allow_nil: true
  validates_length_of :nature, allow_nil: true, maximum: 255
  validates_presence_of :accuracy, :geolocation, :nature, :read_at, :user
  #]VALIDATORS]
  serialize :metadata

  # returns all products whose shape contains the given crumbs
  scope :products, lambda {|*crumbs|
    crumbs.flatten!

    condition = crumbs.present? ? "crumbs.id IN (#{crumbs.map(&:id).join(', ')})" :
                                  "crumbs.id IS NOT NULL"

    Product.distinct.
      joins("INNER JOIN product_readings ON products.id = product_readings.product_id").
      joins("INNER JOIN crumbs ON product_readings.geometry_value ~ crumbs.geolocation").
      where(condition)
  }

  # returns all production supports whose storage shape contains the given crumbs
  # ==== Parameters
  #     - crumbs: an array of crumbs
  # ==== Options
  #     - campaigns: one or several campaigns for which production supports are looked for. Default: current campaigns.
  #       Accepts the same parameters as ProductionSupport.of_campaign since it actually calls this method.
  scope :production_supports, lambda {|crumbs = [], options = {}|
    options[:campaigns] ||= Campaign.currents
    ProductionSupport.of_campaign(options[:campaigns]).distinct.
      joins(:storage).
      where("products.id IN (#{Crumb.products(crumbs).pluck(:id).join(', ')})")
  }

  # returns all crumbs for a given day. Default: the current day
  scope :of_date, lambda{|start_date = Time.now.midnight|
    where(read_at: start_date.midnight..start_date.end_of_day)
  }

  # returns all crumbs, grouped by intervention, for a given user.
  # The result is an array of interventions.
  # An intervention is an array of crumbs, for a user, ordered by read_at,
  # between a start crumb and a stop crumb.
  # if data is inconsistent (e.g. no "stop" crumb corresponding to a "start" crumb)
  # the buffer stores crumbs until the next "start" crumb in the chronological order,
  # and the result receives what is found, whatever the crumbs table content, since the user may always
  # requalify crumbs manually.
  def self.interventions(user)
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
  def intervention
    if nature == 'start'
      start_read_at = read_at.utc
    else
      start_read_at = Crumb.where(user_id: user_id).where(nature: :start).
                            where("read_at <= TIMESTAMP '#{read_at.utc}'").
                            order(read_at: :desc).
                            pluck(:read_at).
                            first.utc
    end
    if nature == 'stop'
      stop_read_at = read_at.utc
    else
      stop_read_at  = Crumb.where(user_id: user_id).
                            where(nature: :stop).
                            where("read_at >= TIMESTAMP '#{read_at.utc}'").
                            order(read_at: :asc).
                            pluck(:read_at).
                            first.utc
    end
    Crumb.where(user_id: user_id).where(read_at: start_read_at..stop_read_at)
  end

  # turns a crumb into an actual intervention and returns the created intervention if any
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
  def convert(options = {})
    res = "foo"
    Ekylibre::Record::Base.transaction do
      options[:actors_ids] ||= []
      actors = Crumb.products(intervention).concat(Product.find(options[:actors_ids])).compact.uniq
      options[:support_id] ||= Crumb.production_supports(intervention.where(nature: :hard_start)).pluck(:id).first
      support = ProductionSupport.find(options[:support_id])
      options[:procedure_name] ||= Intervention.match(actors, options).first[0].name
      procedure = Procedo[options[:procedure_name]]

      # preparing attributes for Intervention#create!
      attributes = {}
      attributes[:started_at] = intervention.where(nature: :start).pluck(:read_at).first
      attributes[:stopped_at] = intervention.where(nature: :stop).pluck(:read_at).first
      attributes[:reference_name] = procedure.name
      attributes[:production] = support.production
      attributes[:production_support] = support
      res = Intervention.create!(attributes)

      # creates casts
      procedure.matching_variables_for(actors).each do |variable, actor|
        attributes = {}
        attributes[:actor] = actor
        attributes[:reference_name] = variable.name
        res.add_cast!(attributes)
      end
    end
    res
  end

end
