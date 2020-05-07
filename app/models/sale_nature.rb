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
# == Table: sale_natures
#
#  active                  :boolean          default(TRUE), not null
#  by_default              :boolean          default(FALSE), not null
#  catalog_id              :integer          not null
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string           not null
#  description             :text
#  downpayment             :boolean          default(FALSE), not null
#  downpayment_minimum     :decimal(19, 4)   default(0.0)
#  downpayment_percentage  :decimal(19, 4)   default(0.0)
#  expiration_delay        :string           not null
#  id                      :integer          not null, primary key
#  journal_id              :integer
#  lock_version            :integer          default(0), not null
#  name                    :string           not null
#  payment_delay           :string           not null
#  payment_mode_complement :text
#  payment_mode_id         :integer
#  provider                :jsonb
#  sales_conditions        :text
#  updated_at              :datetime         not null
#  updater_id              :integer
#

class SaleNature < Ekylibre::Record::Base
  include Providable
  enumerize :payment_delay, in: ['1 week', '30 days', '30 days, end of month', '60 days', '60 days, end of month']
  refers_to :currency
  belongs_to :catalog
  belongs_to :journal
  belongs_to :payment_mode, class_name: 'IncomingPaymentMode'
  has_many :sales, foreign_key: :nature_id, dependent: :restrict_with_exception

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :by_default, :downpayment, inclusion: { in: [true, false] }
  validates :catalog, :currency, :payment_delay, presence: true
  validates :description, :payment_mode_complement, :sales_conditions, length: { maximum: 500_000 }, allow_blank: true
  validates :downpayment_minimum, :downpayment_percentage, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :expiration_delay, :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }

  validates :currency, :journal, presence: true
  validates :currency, match: { with: :journal, message: :currency_does_not_match }
  validates :currency, match: { with: :payment_mode, message: :currency_does_not_match }

  validates :name, uniqueness: true
  validates_delay_format_of :payment_delay, :expiration_delay

  selects_among_all

  scope :actives, -> { where(active: true) }

  before_validation do
    self.expiration_delay = '0 minutes' if expiration_delay.blank?
    self.payment_delay    = '1 week' if payment_delay.blank?
    self.downpayment_minimum ||= 0
    self.downpayment_percentage ||= 0
  end

  class << self
    # Load default sale natures
    def load_defaults(**_options)
      nature = :sales
      usage = :sale
      currency = Preference[:currency]
      journal = Journal.find_by(nature: nature, currency: currency)
      journal ||= Journal.create!(name: "enumerize.journal.nature.#{nature}".t,
                                  nature: nature.to_s, currency: currency,
                                  closed_on: Date.new(1899, 12, 31).end_of_month)
      catalog = Catalog.of_usage(:sale).first
      catalog ||= Catalog.create!(name: "enumerize.catalog.usage.#{usage}".t,
                                  usage: usage, currency: currency)
      unless find_by(name: tc('default.name'))
        create!(
          name: tc('default.name'),
          active: true,
          expiration_delay: '30 day',
          payment_delay: '30 days',
          downpayment: false,
          downpayment_minimum: 300,
          downpayment_percentage: 30,
          journal: journal,
          catalog: catalog,
          currency: currency
        )
      end
    end
  end

  def with_accounting
    ActiveSupport::Deprecation.warn("with_accounting column doesn't exist anymore in sale_natures table")
    true
  end

  alias_method :with_accounting?, :with_accounting
end
