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

  # returns all products whose shape contains the crumb
  def match
    result = []
    product_ids = ProductReading.
        where("geometry_value ~ '#{geolocation}'").pluck(:product_id)
    Product.find(product_ids).each do |product|
      result << product
      # TODO: remove this when Ekylibre manages geolocation for equipment and all products in general
      if product.is_a? BuildingDivision
        product.contains(:product, read_at).to_a.each do |localization|
          result << localization.product
        end
      end
    end
    result
  end
  
  # returns the current production support on which the crumb is located
  def production_support
    ProductionSupport.of_campaign(Campaign.currents).includes({production: [:activity, :campaign, :variant]}, :storage)
      .joins(:storage)
      .joins("INNER JOIN product_readings ON products.id = product_readings.product_id")
      .where("geometry_value ~ geolocation")    
  end

  # listing possibles products matching points
  # using postgis operators on geometry objects
  # == params:
  #   - crumbs, an array of Crumb objects
  # == options
  #   - intersection: matches all actors intersecting the crumbs. Expects a boolean. Default false. By default
  #     the method returns only actors that include all the crumbs.
  #   - natures: matches all actors whose nature is given.
  # @returns: an array of products whose shape contains or intersects the crumbs
  def self.match(crumbs, options = {})
    operator = '~'
    operator = '&&' if options[:intersection]
    options[:natures] ||= [Product]
    crumbs = [crumbs].flatten
    crumbs_id = []
    crumbs.each {|crumb| crumbs_id << crumb.id }
    actors_id = ProductReading.
        where("geometry_value #{operator} (SELECT ST_Multi(ST_Collect(geolocation)) FROM (SELECT geolocation FROM crumbs WHERE id IN (#{crumbs_id.join(', ')})) AS m)").pluck(:product_id)
    Product.find(actors_id).
        delete_if{|actor| options[:natures].
        flatten.
        inject(false){|one_of_previous, klass| actor.is_a?(klass) || one_of_previous} == false}
  end

  # returns all the interventions for the current user
  # an intervention is an array of crumbs, ordered by read_at, between a 'start' crumb and a 'stop' crumb
  def self.interventions(user_id)
    buffer = []
    result = []
    Crumb.where(user_id: user_id).order(read_at: :asc).each do |crumb|
      buffer << crumb
      if crumb.nature == 'stop'
        result << buffer
        buffer = []
      end
    end
    result
  end

end
