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
# == Table: gaps
#
#  accounted_at     :datetime
#  affair_id        :integer          not null
#  amount           :decimal(19, 4)   default(0.0), not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string(3)        not null
#  direction        :string(255)      not null
#  entity_id        :integer          not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  number           :string(255)      not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#
class Gap < Ekylibre::Record::Base
  enumerize :direction, in: [:profit, :loss], predicates: true
  belongs_to :journal_entry
  belongs_to :entity

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :direction, :number, allow_nil: true, maximum: 255
  validates_presence_of :affair, :amount, :currency, :direction, :entity, :number
  #]VALIDATORS]

  acts_as_numbered
  acts_as_affairable debit: :profit?, third: :entity, role: :client, dealt_on: :created_at
  alias_attribute :label, :number
  alias_attribute :label, :number
  alias_attribute :label, :number

  bookkeep do |b|
    # TODO Adds journal entry for gap
  end


end
