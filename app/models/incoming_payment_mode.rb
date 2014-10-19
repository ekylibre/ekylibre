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
# == Table: incoming_payment_modes
#
#  active                  :boolean
#  cash_id                 :integer
#  commission_account_id   :integer
#  commission_base_amount  :decimal(19, 4)   default(0.0), not null
#  commission_percentage   :decimal(19, 4)   default(0.0), not null
#  created_at              :datetime         not null
#  creator_id              :integer
#  depositables_account_id :integer
#  depositables_journal_id :integer
#  detail_payments         :boolean          not null
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  name                    :string(50)       not null
#  position                :integer
#  updated_at              :datetime         not null
#  updater_id              :integer
#  with_accounting         :boolean          not null
#  with_commission         :boolean          not null
#  with_deposit            :boolean          not null
#


class IncomingPaymentMode < Ekylibre::Record::Base
  attr_readonly :cash_id, :cash
  acts_as_list
  belongs_to :cash
  belongs_to :commission_account, class_name: "Account"
  belongs_to :depositables_account, class_name: "Account"
  belongs_to :depositables_journal, class_name: "Journal"
  has_many :depositable_payments, -> { where(:deposit_id => nil) }, class_name: "IncomingPayment", foreign_key: :mode_id
  has_many :payments, foreign_key: :mode_id, class_name: "IncomingPayment"
  # has_many :unlocked_payments, -> { where("journal_entry_id IN (SELECT id FROM #{JournalEntry.table_name} WHERE state=#{connection.quote("draft")})") }, foreign_key: :mode_id, class_name: "IncomingPayment"
  has_many :unlocked_payments, -> { where(journal_entry_id: JournalEntry.where(state: "draft")) }, foreign_key: :mode_id, class_name: "IncomingPayment"

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :commission_base_amount, :commission_percentage, allow_nil: true
  validates_length_of :name, allow_nil: true, maximum: 50
  validates_inclusion_of :detail_payments, :with_accounting, :with_commission, :with_deposit, in: [true, false]
  validates_presence_of :commission_base_amount, :commission_percentage, :name
  #]VALIDATORS]
  validates_numericality_of :commission_percentage, :greater_than_or_equal_to => 0, if: :with_commission?
  validates_presence_of :depositables_account, if: :with_deposit?
  validates_presence_of :depositables_journal, if: :with_deposit?
  validates_presence_of :cash

  delegate :currency, to: :cash
  delegate :journal, to: :cash, prefix: true

  scope :depositers, -> { with_deposit.order(:name) }
  scope :with_deposit, -> { where(with_deposit: true) }

  before_validation do
    if self.cash and self.cash.cash_box?
      self.with_deposit = false
      self.with_commission = false
    end
    unless self.with_deposit?
      self.depositables_account = nil
      self.depositables_journal = nil
    end
    unless self.with_commission
      self.commission_base_amount ||= 0
      self.commission_percentage  ||= 0
    end
    true
  end

  protect(on: :destroy) do
    self.payments.any?
  end

  def commission_amount(amount)
    return (amount * self.commission_percentage * 0.01 + self.commission_base_amount).round(2)
  end

  def reflect
    self.unlocked_payments.find_each do |payment|
      payment.update_attributes(commission_account_id: nil, commission_amount: nil)
    end
  end

end
