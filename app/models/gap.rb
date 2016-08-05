# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: gaps
#
#  accounted_at     :datetime
#  affair_id        :integer
#  amount           :decimal(19, 4)   default(0.0), not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string           not null
#  direction        :string           not null
#  entity_id        :integer          not null
#  entity_role      :string           not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  number           :string           not null
#  pretax_amount    :decimal(19, 4)   default(0.0), not null
#  printed_at       :datetime         not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class Gap < Ekylibre::Record::Base
  enumerize :direction, in: [:profit, :loss], predicates: true
  enumerize :entity_role, in: [:client, :supplier], predicates: true
  refers_to :currency
  belongs_to :journal_entry
  belongs_to :entity
  has_many :items, class_name: 'GapItem', inverse_of: :gap, dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, :direction, :entity, :entity_role, presence: true
  validates :number, presence: true, length: { maximum: 500 }
  validates :printed_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }

  accepts_nested_attributes_for :items
  acts_as_numbered
  acts_as_affairable :entity, debit: :loss?, role: :entity_role, good: :profit?
  alias_attribute :label, :number

  before_validation do
    self.printed_at ||= Time.zone.now
  end

  bookkeep do |b|
    b.journal_entry(Journal.used_for_gaps, printed_on: self.printed_at.to_date, unless: amount.zero?) do |entry|
      label = tc(:bookkeep, resource: direction.l, number: number, entity: entity.full_name)
      if profit?
        entry.add_debit(label, entity.account(entity_role).id, amount)
        for item in items
          entry.add_credit(label, Account.find_or_import_from_nomenclature(:other_usual_running_profits), item.pretax_amount)
          entry.add_credit(label, item.tax.collect_account_id, item.taxes_amount)
        end
      else
        entry.add_credit(label, entity.account(entity_role).id, amount)
        for item in items
          entry.add_debit(label, Account.find_or_import_from_nomenclature(:other_usual_running_expenses), item.pretax_amount)
          entry.add_debit(label, item.tax.deduction_account_id, item.taxes_amount)
        end
      end
    end
  end

  # Gives the amount to use for affair bookkeeping
  def deal_amount
    (loss? ? -amount : amount)
  end
end
