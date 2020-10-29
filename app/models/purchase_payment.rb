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
# == Table: outgoing_payments
#
#  accounted_at      :datetime
#  affair_id         :integer
#  amount            :decimal(19, 4)   default(0.0), not null
#  bank_check_number :string
#  cash_id           :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string           not null
#  custom_fields     :jsonb
#  delivered         :boolean          default(FALSE), not null
#  downpayment       :boolean          default(FALSE), not null
#  id                :integer          not null, primary key
#  journal_entry_id  :integer
#  list_id           :integer
#  lock_version      :integer          default(0), not null
#  mode_id           :integer          not null
#  number            :string
#  paid_at           :datetime
#  payee_id          :integer          not null
#  position          :integer
#  responsible_id    :integer          not null
#  to_bank_at        :datetime         not null
#  type              :string
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class PurchasePayment < OutgoingPayment
  acts_as_affairable :payee, dealt_at: :to_bank_at, debit: false, class_name: 'PurchaseAffair'

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    label = tc(:bookkeep, resource: self.class.model_name.human, number: number, payee: payee.full_name, mode: mode.name, check_number: bank_check_number)
    b.journal_entry(mode.cash.journal, printed_on: to_bank_at.to_date, if: (mode.with_accounting? && delivered)) do |entry|
      entry.add_debit(label, payee.account(:supplier).id, amount, as: :payee, resource: payee)
      entry.add_credit(label, mode.cash.account_id, amount, as: :bank)
    end
  end
end
