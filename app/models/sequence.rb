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
# == Table: sequences
#
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  last_cweek       :integer
#  last_month       :integer
#  last_number      :integer
#  last_year        :integer
#  lock_version     :integer          default(0), not null
#  name             :string(255)      not null
#  number_format    :string(255)      not null
#  number_increment :integer          default(1), not null
#  number_start     :integer          default(1), not null
#  period           :string(255)      default("number"), not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#  usage            :string(255)
#


class Sequence < Ekylibre::Record::Base
  enumerize :period, in: [:cweek, :month, :number, :year]
  # TODO: Adds all usage for sequence? or register_usage like Account ?
  enumerize :usage, in: [:affairs, :animals, :campaigns, :cash_transfers, :deposits, :entities, :financial_assets, :gaps, :incoming_deliveries, :incoming_payments, :interventions, :outgoing_deliveries, :outgoing_payments, :plants, :purchases, :sales_invoices, :sales, :stock_transfers, :subscriptions, :transports]
  # cattr_reader :usages

  REPLACE_REGEXP = Regexp.new('\[(' + self.period.values.join('|') + ')(\|(\d+)(\|([^\]]*))?)?\]').freeze

  has_many :preferences, :as => :record_value
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :last_cweek, :last_month, :last_number, :last_year, :number_increment, :number_start, allow_nil: true, only_integer: true
  validates_length_of :name, :number_format, :period, :usage, allow_nil: true, maximum: 255
  validates_presence_of :name, :number_format, :number_increment, :number_start, :period
  #]VALIDATORS]
  validates_inclusion_of  :period, in: self.period.values
  validates_inclusion_of  :usage, in: self.usage.values, allow_nil: true
  validates_uniqueness_of :number_format
  validates_uniqueness_of :usage, if: :used?

  scope :of_usage, lambda { |usage| where(:usage => usage.to_s).order(:id) }

  before_validation do
    self.period ||= 'number'
  end

  protect(on: :destroy) do
    self.preferences.any?
  end

  def self.of(usage)
    self.of_usage(usage).first
  end

  def self.best_period_for(format)
    keys = []
    format.match(REPLACE_REGEXP) do |m|
      key, size, pattern = $1, $3, $5
      keys << key.to_sym
    end
    keys.delete(:number)
    # Because period size correspond to alphabetical order
    # We use thaht to find the littlest period
    return keys.sort.first
  end

  def self.load_defaults
    for usage in self.usage.values
      unless sequence = self.find_by_usage(usage)
        sequence = self.new(usage: usage)
        sequence.name = sequence.usage.text
        sequence.number_format = "models.sequence.default.#{usage}".t(default: sequence.usage.to_s.split(/\_/).map{|w| w[0..0]}.join.upcase + "[number|12]")
        sequence.period = best_period_for(sequence.number_format)
        sequence.save
      end
    end
  end

  def used?
    !self.usage.blank?
  end

  def compute(number=nil)
    number ||= self.last_number
    today = Date.today
    self['number_format'].gsub(REPLACE_REGEXP) do |m|
      key, size, pattern = $1, $3, $5
      string = (key == 'number' ? number : today.send(key)).to_s
      size.nil? ? string : string.rjust(size.to_i, pattern||'0')
    end
  end

  # Produces the next value of the sequence and update last value in DB
  def next_value
    self.reload
    today = Date.today
    period = self.period.to_s
    if self.last_number.nil?
      self.last_number  = self.number_start
    else
      self.last_number += self.number_increment
    end
    if period != 'number' and not self.send('last_'+period).nil?
      self.last_number = self.number_start if self.send('last_'+period) != today.send(period) or self.last_year != today.year
    end
    self.last_year, self.last_month, self.last_cweek = today.year, today.month, today.cweek
    raise [self.updateable?, self.destroyable?, self.errors.to_hash].inspect unless self.save
    return self.compute
  end

end

