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
# == Table: analyses
#
#  analysed_at      :datetime
#  analyser_id      :integer
#  created_at       :datetime         not null
#  creator_id       :integer
#  description      :text
#  geolocation      :geometry({:srid=>4326, :type=>"point"})
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  nature           :string           not null
#  number           :string           not null
#  product_id       :integer
#  reference_number :string
#  sampled_at       :datetime         not null
#  sampler_id       :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class Analysis < Ekylibre::Record::Base
  enumerize :nature, in: Nomen::AnalysisNatures.all, predicates: true
  belongs_to :analyser, class_name: 'Entity'
  belongs_to :sampler, class_name: 'Entity'
  belongs_to :product
  has_many :items, class_name: 'AnalysisItem', foreign_key: :analysis_id, inverse_of: :analysis, dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :analysed_at, :sampled_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_presence_of :nature, :number, :sampled_at
  # ]VALIDATORS]

  acts_as_numbered

  accepts_nested_attributes_for :items, allow_destroy: true

  scope :between, lambda { |started_at, stopped_at|
    where(sampled_at: started_at..stopped_at)
  }

  after_save do
    reload.items.each(&:save!)
  end

  def geolocation=(value)
    if value.is_a?(String) && value =~ /\A\{.*\}\z/
      value = Charta::Geometry.new(JSON.parse(value).to_json, :WGS84).to_rgeo
    elsif !value.blank?
      value = Charta::Geometry.new(value).to_rgeo
    end
    self['geolocation'] = value
  end

  # Measure a product for a given indicator
  def read!(indicator, value, options = {})
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicators[indicator]
      fail ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    fail ArgumentError, 'Value must be given' if value.nil?
    options[:indicator_name] = indicator.name
    unless item = items.find_by(indicator_name: indicator.name)
      item = items.build(indicator_name: indicator.name)
    end
    item.value = value
    item.save!
    item
  end

  def get(indicator, *args)
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicators[indicator]
      fail ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    options = args.extract_options!
    items = self.items.where(indicator_name: indicator.name.to_s)
    return items.first.value if items.any?
    nil
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicators.all.include?(method_name.to_s)
      return get(method_name, *args)
    end
    super
  end
end
