# = Informations
#
# == License
#
# Ekylibre - Simple ERP
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
# == Table: purchase_natures
#
#  active          :boolean          default(TRUE), not null
#  by_default      :boolean          not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  currency        :string(3)        not null
#  description     :text
#  id              :integer          not null, primary key
#  journal_id      :integer
#  lock_version    :integer          default(0), not null
#  name            :string(255)
#  updated_at      :datetime         not null
#  updater_id      :integer
#  with_accounting :boolean          not null
#
class PurchaseNature < Ekylibre::Record::Base
  belongs_to :journal
  has_many :purchases
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :name, allow_nil: true, maximum: 255
  validates_inclusion_of :active, :by_default, :with_accounting, in: [true, false]
  validates_presence_of :currency
  #]VALIDATORS]
  validates_presence_of :journal, if: :with_accounting?
  validates_presence_of :currency
  validates_uniqueness_of :name

  selects_among_all

  scope :actives, -> { where(active: true) }

  validate do
    self.journal = nil unless self.with_accounting?
    if self.journal
      errors.add(:journal, :currency_does_not_match) if self.currency != self.journal.currency
    end
  end

end
