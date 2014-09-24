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
# == Table: transfers
#
#  accounted_at     :datetime
#  affair_id        :integer
#  amount           :decimal(19, 4)   not null
#  client_id        :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string(3)        not null
#  description      :string(255)
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  label            :string(255)
#  lock_version     :integer          default(0), not null
#  number           :string(255)
#  printed_at       :datetime
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class Transfer < Ekylibre::Record::Base
  belongs_to :client, class_name: "Entity"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :description, :label, :number, allow_nil: true, maximum: 255
  validates_presence_of :amount, :client, :currency
  #]VALIDATORS]
  validates_presence_of :printed_at, :client

  acts_as_affairable :client, dealt_at: :printed_at, debit: false
  acts_as_numbered

  before_validation do
    self.printed_at ||= Time.now
  end

  bookkeep(on: :nothing) do |b|
  end

end
