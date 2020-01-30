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
# == Table: incoming_payment_modes
#
#  active                  :boolean          default(FALSE)
#  cash_id                 :integer
#  commission_account_id   :integer
#  commission_base_amount  :decimal(19, 4)   default(0.0), not null
#  commission_percentage   :decimal(19, 4)   default(0.0), not null
#  created_at              :datetime         not null
#  creator_id              :integer
#  depositables_account_id :integer
#  depositables_journal_id :integer
#  detail_payments         :boolean          default(FALSE), not null
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  name                    :string           not null
#  position                :integer
#  updated_at              :datetime         not null
#  updater_id              :integer
#  with_accounting         :boolean          default(FALSE), not null
#  with_commission         :boolean          default(FALSE), not null
#  with_deposit            :boolean          default(FALSE), not null
#

class IncomingPaymentMode < Ekylibre::Record::Base
  attr_readonly :cash_id, :cash
  acts_as_list
  belongs_to :cash
  belongs_to :commission_account, class_name: 'Account'
  belongs_to :depositables_account, class_name: 'Account'
  belongs_to :depositables_journal, class_name: 'Journal'
  has_many :depositable_payments, -> { where(deposit_id: nil) }, class_name: 'IncomingPayment', foreign_key: :mode_id
  has_many :payments, foreign_key: :mode_id, class_name: 'IncomingPayment', dependent: :restrict_with_exception
  # has_many :unlocked_payments, -> { where("journal_entry_id IN (SELECT id FROM #{JournalEntry.table_name} WHERE state=#{connection.quote("draft")})") }, foreign_key: :mode_id, class_name: "IncomingPayment"
  has_many :unlocked_payments, -> { where(journal_entry_id: JournalEntry.where(state: 'draft')) }, foreign_key: :mode_id, class_name: 'IncomingPayment'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, inclusion: { in: [true, false] }, allow_blank: true
  validates :commission_base_amount, :commission_percentage, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :detail_payments, :with_accounting, :with_commission, :with_deposit, inclusion: { in: [true, false] }
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :name, length: { allow_nil: true, maximum: 50 }
  validates :commission_percentage, numericality: { greater_than_or_equal_to: 0, if: :with_commission? }
  validates :depositables_account, presence: { if: :with_deposit? }
  validates :depositables_journal, presence: { if: :with_deposit? }
  validates :cash, presence: true

  delegate :currency, to: :cash
  delegate :journal, to: :cash, prefix: true

  scope :depositers, -> { where(with_deposit: true).order(:name) }
  scope :matching_cash, ->(id) { where(cash_id: id) }

  before_validation do
    if cash && cash.cash_box?
      self.with_deposit = false
      self.with_commission = false
    end
    unless with_deposit?
      self.depositables_account = nil
      self.depositables_journal = nil
    end
    unless with_commission
      self.commission_base_amount ||= 0
      self.commission_percentage ||= 0
    end
    true
  end

  protect(on: :destroy) do
    payments.any?
  end

  def commission_amount(amount)
    (amount * self.commission_percentage * 0.01 + self.commission_base_amount).round(2)
  end

  def reflect
    unlocked_payments.find_each do |payment|
      payment.update_attributes(commission_account_id: nil, commission_amount: nil)
    end
  end

  def self.load_defaults(**_options)
    %w[cash check transfer].each do |nature|
      cash_nature = nature == 'cash' ? :cash_box : :bank_account
      cash = Cash.find_by(nature: cash_nature)
      next unless cash
      attributes = {
        name: IncomingPaymentMode.tc("default.#{nature}.name"),
        with_accounting: true,
        cash: cash,
        with_deposit: (nature == 'check')
      }
      journal = Journal.find_by(nature: 'bank')
      if attributes[:with_deposit] && journal
        attributes[:depositables_journal] = journal
        attributes[:depositables_account] = Account.find_or_import_from_nomenclature(:pending_deposit_payments)
      else
        attributes[:with_deposit] = false
      end
      create!(attributes)
    end
  end
end
