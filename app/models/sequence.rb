# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
#  name             :string           not null
#  number_format    :string           not null
#  number_increment :integer          default(1), not null
#  number_start     :integer          default(1), not null
#  period           :string           default("number"), not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#  usage            :string
#

class Sequence < Ekylibre::Record::Base
  enumerize :period, in: %i[cweek month number year]
  enumerize :usage, in: %i[affairs analyses animals campaigns cash_transfers contracts debt_transfers deliveries deposits documents entities fixed_assets gaps incoming_payments inspections interventions inventories opportunities outgoing_payments outgoing_payment_lists parcels payslips plants plant_countings products product_natures product_nature_categories product_nature_variants purchases sales sales_invoices subscriptions tax_declarations]

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :last_cweek, :last_month, :last_number, :last_year, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, :number_format, presence: true, length: { maximum: 500 }
  validates :number_increment, :number_start, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :period, presence: true
  # ]VALIDATORS]
  validates :period, inclusion: { in: period.values }
  validates :usage, inclusion: { in: usage.values, allow_nil: true }
  validates :number_format, uniqueness: true
  validates :usage, uniqueness: { if: :used? }

  scope :of_usage, ->(usage) { where(usage: usage.to_s).order(:id) }

  before_validation do
    self.period ||= 'number'
  end

  class << self
    def of(usage)
      sequence = find_by(usage: usage)
      return sequence if sequence
      sequence = new(usage: usage)
      sequence.name = begin
                        sequence.usage.to_s.classify.constantize.model_name.human
                      rescue
                        sequence.usage
                      end
      sequence.number_format = tc("default.#{usage}", default: sequence.usage.to_s.split(/\_/).map { |w| w[0..0] }.join.upcase + '[number|12]')
      while find_by(number_format: sequence.number_format)
        sequence.number_format = ('A'..'Z').to_a.sample + sequence.number_format
      end
      sequence.period = best_period_for(sequence.number_format)
      sequence.save!
      sequence
    end

    def best_period_for(format)
      keys = []
      format.match(replace_regexp) do |_|
        key = Regexp.last_match(1)
        size = Regexp.last_match(3)
        pattern = Regexp.last_match(5)
        keys << key.to_sym
      end
      keys.delete(:number)
      # Because period size correspond to alphabetical order
      # We use thaht to find the littlest period
      keys.sort.first
    end

    # Load defaults sequences
    def load_defaults(**_options)
      usage.values.each do |usage|
        of(usage)
      end
    end

    def replace_regexp
      @replace_regexp ||= Regexp.new('\[(' + self.period.values.join('|') + ')(\|(\d+)(\|([^\]]*))?)?\]').freeze
    end

    def compute(format, values = {})
      format.gsub(replace_regexp) do |_|
        key = Regexp.last_match(1).to_sym
        size = Regexp.last_match(3)
        pattern = Regexp.last_match(5)
        string = values[key].to_s
        size.blank? ? string : string.rjust(size.to_i, pattern || '0')
      end
    end
  end

  def used?
    usage.present?
  end

  def last_value
    compute(
      number: last_number,
      cweek: last_cweek,
      month: last_month,
      year: last_year
    )
  end

  def next_value(today = nil)
    compute(next_counters(today))
  end

  # Produces the next value of the sequence and update last value in DB
  def next_value!
    reload
    # FIXME: Prevent concurrency access to the method
    counters = next_counters
    self.last_number = counters[:number]
    self.last_cweek = counters[:cweek]
    self.last_month = counters[:month]
    self.last_year = counters[:year]
    save!
    compute(counters)
  end

  protected

  # Compute next counters values
  def next_counters(today = nil)
    today ||= Time.zone.today
    counters = { year: today.year, month: today.month, cweek: today.cweek }
    period = self.period.to_sym
    counters[:number] = last_number
    if counters[:number].nil?
      counters[:number] = number_start
    else
      counters[:number] += number_increment
    end
    last_period_value = send('last_' + period.to_s)
    if period != :number && last_period_value.present?
      if last_period_value != counters[period.to_sym] || last_year != counters[:year]
        counters[:number] = number_start
      end
    end
    counters
  end

  # Compute number with number_format and given counters
  def compute(counters)
    self.class.compute(number_format, counters)
  end
end
