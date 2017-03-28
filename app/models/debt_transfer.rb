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
#  accounted_at                             :datetime
#  amount                                   :decimal(, )
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  currency                                 :string           not null
#  id                                       :integer          not null, primary key
#  lock_version                             :integer          default(0), not null
#  purchase_affair_id                       :integer          not null
#  purchase_regularization_journal_entry_id :integer
#  sale_affair_id                           :integer          not null
#  sale_regularization_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#
class DebtTransfer < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, numericality: true, allow_blank: true
  validates :currency, presence: true, length: { maximum: 500 }
  validates :purchase_affair, :sale_affair, presence: true
  # ]VALIDATORS]

  belongs_to :purchase_regularization_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :sale_regularization_journal_entry, class_name: 'JournalEntry', dependent: :destroy

  belongs_to :purchase_affair
  belongs_to :sale_affair

  ####
  ## From third's point of view
  ## amount < 0 : Purchase affair transferred to Sale Affair
  ## amount > 0 : Sale affair transferred to Purchase Affair
  ####

  before_validation do
    self.currency = sale_affair.currency
  end

  validate do
    errors.add(:cannot_add_debt_transfer_on_multi_thirds) unless sale_affair.third == purchase_affair.third
    errors.add(:currency_doesnt_match) unless sale_affair.currency == purchase_affair.currency
    errors.add(:affair_already_balanced) unless sale_affair.journal_entry_items_unbalanced? && purchase_affair.journal_entry_items_unbalanced?
    errors.add(:amount_cant_be_empty) unless amount.present? && (amount != 0)
  end

  bookkeep do |b|

    account = Account.find_or_import_from_nomenclature(:sundry_debtors_and_creditors)

    if amount < 0
      originator_affair = purchase_affair
      target_affair = sale_affair
      transfer = :purchase
      third_account = originator_affair.third.supplier_account
    else
      originator_affair = sale_affair
      target_affair = purchase_affair
      transfer = :sale
      third_account = originator_affair.third.client_account
    end

    b.journal_entry(originator_affair.journal_entry ? originator_affair.journal_entry.journal : originator_affair.originator.journal_entry.journal, printed_on: created_at.to_date, as: "#{transfer}_regularization", if: (originator_affair.unbalanced? && target_affair.unbalanced? && originator_affair.deals_count > 0)) do |entry|
      label = tc("#{transfer}_regularization", resource: originator_affair.class.model_name.human, number: originator_affair.number, entity: originator_affair.third.full_name)

      entry.add_debit(label, third_account, originator_affair.balance, resource: originator_affair.originator, as: "#{transfer}_regularization")
      entry.add_credit(label, account, originator_affair.balance, resource: originator_affair.originator, as: "#{transfer}_regularization")
    end

  end
end
