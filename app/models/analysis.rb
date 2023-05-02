# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
#  analysed_at            :datetime
#  analyser_id            :integer(4)
#  created_at             :datetime         not null
#  creator_id             :integer(4)
#  cultivable_zone_id     :integer(4)
#  custom_fields          :jsonb
#  description            :text
#  geolocation            :geometry({:srid=>4326, :type=>"st_point"})
#  host_id                :integer(4)
#  id                     :integer(4)       not null, primary key
#  lock_version           :integer(4)       default(0), not null
#  nature                 :string           not null
#  number                 :string           not null
#  product_id             :integer(4)
#  reference_number       :string
#  retrieval_message      :string
#  retrieval_status       :string           default("ok"), not null
#  sampled_at             :datetime         not null
#  sampler_id             :integer(4)
#  sampling_temporal_mode :string           default("instant"), not null
#  sensor_id              :integer(4)
#  stopped_at             :datetime
#  updated_at             :datetime         not null
#  updater_id             :integer(4)
#

class Analysis < ApplicationRecord
  include Attachable
  include Customizable
  enumerize :retrieval_status, in: %i[ok controller_error internal_error sensor_error error], predicates: true
  refers_to :nature, class_name: 'AnalysisNature'
  belongs_to :analyser, class_name: 'Entity'
  belongs_to :cultivable_zone, class_name: 'CultivableZone'
  belongs_to :sampler, class_name: 'Entity'
  belongs_to :product
  belongs_to :sensor
  belongs_to :host, class_name: 'Product', foreign_key: :host_id
  has_many :items, class_name: 'AnalysisItem', foreign_key: :analysis_id, inverse_of: :analysis, dependent: :destroy
  has_one :wine_incoming_harvest

  has_geometry :geolocation, type: :point

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :analysed_at, :stopped_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :nature, :retrieval_status, presence: true
  validates :number, :sampling_temporal_mode, presence: true, length: { maximum: 500 }
  validates :reference_number, :retrieval_message, length: { maximum: 500 }, allow_blank: true
  validates :sampled_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  # ]VALIDATORS]

  acts_as_numbered

  accepts_nested_attributes_for :items, allow_destroy: true

  scope :between, lambda { |started_at, stopped_at|
    where(sampled_at: started_at..stopped_at)
  }

  scope :with_indicator, lambda { |indicator|
    where(id: AnalysisItem.where(indicator_name: indicator).select(:analysis_id))
  }

  before_validation do
    self.sampled_at ||= Time.zone.now
  end

  after_save do
    reload.items.each(&:save!)
  end

  protect(on: :destroy) do
    wine_incoming_harvest.present?
  end

  # Measure a product for a given indicator
  def read!(indicator, value, options = {})
    unless indicator.is_a?(Onoma::Item) || indicator = Onoma::Indicator[indicator]
      raise ArgumentError.new("Unknown indicator #{indicator.inspect}. Expecting one of them: #{Onoma::Indicator.all.sort.to_sentence}.")
    end
    raise ArgumentError.new('Value must be given') if value.nil?

    options[:indicator_name] = indicator.name
    unless item = items.find_by(indicator_name: indicator.name)
      item = items.build(indicator_name: indicator.name)
    end
    item.value = value
    item.save!
    item
  end

  def get(indicator, *args)
    unless indicator.is_a?(Onoma::Item) || indicator = Onoma::Indicator[indicator]
      raise ArgumentError.new("Unknown indicator #{indicator.inspect}. Expecting one of them: #{Onoma::Indicator.all.sort.to_sentence}.")
    end

    options = args.extract_options!
    items = self.items.where(indicator_name: indicator.name.to_s)
    return items.first.value if items.any?

    nil
  end

  # Returns if status changed since previous call
  def status_changed?
    return true unless previous

    previous.retrieval_status != retrieval_status
  end

  # Returns previous analysis. Works with sensors only.
  def previous
    sensor.analyses.where('sampled_at < ?', self.sampled_at).order(sampled_at: :desc).first
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Onoma::Indicator.all.include?(method_name.to_s)
      return get(method_name, *args)
    end

    super
  end

  def has_attachments
    self.attachments.present?
  end
end
