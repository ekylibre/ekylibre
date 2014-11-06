# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
#  by_default              :boolean          not null
#  catalog_id              :integer          not null
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string(3)        not null
#  description             :text
#  downpayment             :boolean          not null
#  downpayment_minimum     :decimal(19, 4)   default(0.0)
#  downpayment_percentage  :decimal(19, 4)   default(0.0)
#  expiration_delay        :string(255)      not null
#  id                      :integer          not null, primary key
#  journal_id              :integer
#  lock_version            :integer          default(0), not null
#  name                    :string(255)      not null
#  payment_delay           :string(255)      not null
#  payment_mode_complement :text
#  payment_mode_id         :integer
#  sales_conditions        :text
#  updated_at              :datetime         not null
#  updater_id              :integer
#  with_accounting         :boolean          not null
#


class SaleNature < Ekylibre::Record::Base
  belongs_to :catalog
  belongs_to :journal
  belongs_to :payment_mode, class_name: "IncomingPaymentMode"
  has_many :sales

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :downpayment_minimum, :downpayment_percentage, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :expiration_delay, :name, :payment_delay, allow_nil: true, maximum: 255
  validates_inclusion_of :active, :by_default, :downpayment, :with_accounting, in: [true, false]
  validates_presence_of :catalog, :currency, :expiration_delay, :name, :payment_delay
  #]VALIDATORS]
  validates_presence_of :journal, if: :with_accounting?
  validates_presence_of :currency
  validates_uniqueness_of :name
  validates_delay_format_of :payment_delay, :expiration_delay

  selects_among_all

  scope :actives, -> { where(active: true) }

  before_validation do
    self.expiration_delay = "0 minutes" if self.expiration_delay.blank?
    self.payment_delay    = "0 minutes" if self.payment_delay.blank?
    self.downpayment_minimum    ||= 0
    self.downpayment_percentage ||= 0
  end

  validate do
    if self.journal
      unless self.currency == self.journal.currency
        errors.add(:journal, :currency_does_not_match, currency: self.currency)
      end
    end
    if self.payment_mode
      unless self.currency == self.payment_mode.currency
        errors.add(:payment_mode, :currency_does_not_match, currency: self.currency)
      end
    end
  end

end
