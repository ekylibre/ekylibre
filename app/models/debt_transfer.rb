# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: debt_transfers
#
#  accounted_at            :datetime
#  affair_id               :integer          not null
#  amount                  :decimal(19, 4)   default(0.0)
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string           not null
#  debt_transfer_affair_id :integer          not null
#  id                      :integer          not null, primary key
#  journal_entry_id        :integer
#  lock_version            :integer          default(0), not null
#  nature                  :string           not null
#  number                  :string
#  updated_at              :datetime         not null
#  updater_id              :integer
#

####
## Generate two records with mirroring
####
class DebtTransfer < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :currency, presence: true, length: { maximum: 500 }
  validates :affair, :debt_transfer_affair, :nature, presence: true
  validates :number, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]

  belongs_to :journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :affair, class_name: 'Affair', inverse_of: :debt_transfers
  belongs_to :debt_transfer_affair, class_name: 'Affair', inverse_of: :debt_regularizations

  enumerize :nature, in: %i[sale_regularization purchase_regularization]

  acts_as_affairable :third

  acts_as_numbered

  before_validation do
    self.currency ||= affair.currency
    self.amount = [affair.balance.abs, debt_transfer_affair.balance.abs].sort.first
    self.nature ||= if debt_transfer_affair.is_a?(PurchaseAffair) && affair.is_a?(SaleAffair)
                      :sale_regularization
                    elsif debt_transfer_affair.is_a?(SaleAffair) && affair.is_a?(PurchaseAffair)
                      :purchase_regularization
                    else
                      raise "can't run a debt transfer with homogeneous affairs"
                    end
  end

  validate do
    errors.add(:third, :invalid) unless affair.third == debt_transfer_affair.third
    errors.add(:currency, :invalid) unless affair.currency == debt_transfer_affair.currency
    errors.add(:amount, :empty) unless amount.present? && (amount != 0)
  end

  before_destroy do
    # from affair (the 'target'), we destroy regularizations
    mirror_nature = (nature == :sale_regularization ? :purchase_regularization : :sale_regularization)
    affair.debt_regularizations.find_by(nature: mirror_nature, amount: amount).delete
    true
  end

  class << self
    def create_and_reflect!(args)
      record = create! args
      reflect! record
      record
    end

    def reflect!(record)
      create!(affair: record.debt_transfer_affair,
              debt_transfer_affair: record.affair,
              currency: record.currency,
              amount: record.amount,
              nature: record.nature == :sale_regularization ? :purchase_regularization : :sale_regularization)
    end

    def regularization_account
      Account.find_or_import_from_nomenclature(:sundry_debtors_and_creditors)
    end
  end

  bookkeep do |b|
    # TODO: refactor
    if nature == :purchase_regularization

      # Debit on supplier account + credit on regularization account
      b.journal_entry(debt_transfer_affair.journal_entry ? debt_transfer_affair.journal_entry.journal : debt_transfer_affair.originator.journal_entry.journal, printed_on: created_at.to_date, if: (debt_transfer_affair.unbalanced? && affair.unbalanced? && debt_transfer_affair.deals_count > 0)) do |entry|
        label = tc(nature, resource: debt_transfer_affair.class.model_name.human, number: debt_transfer_affair.number, entity: debt_transfer_affair.third.full_name)

        entry.add_debit(label, debt_transfer_affair.third.supplier_account, amount, resource: affair.originator, as: :sale)
        entry.add_credit(label, self.class.regularization_account, amount, resource: debt_transfer_affair.originator, as: nature)
      end
    end

    if nature == :sale_regularization

      # debit on regularization account + Credit on client account
      b.journal_entry(affair.journal_entry ? affair.journal_entry.journal : affair.originator.journal_entry.journal, printed_on: created_at.to_date, if: (debt_transfer_affair.unbalanced? && affair.unbalanced? && affair.deals_count > 0)) do |entry|
        label = tc(nature, resource: affair.class.model_name.human, number: affair.number, entity: affair.third.full_name)

        entry.add_debit(label, self.class.regularization_account, amount, resource: debt_transfer_affair.originator, as: nature)
        entry.add_credit(label, affair.third.client_account, amount, resource: affair.originator, as: :purchase)
      end
    end
  end

  delegate :third, to: :affair
end
