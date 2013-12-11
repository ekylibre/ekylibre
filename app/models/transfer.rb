# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2013 Brice Texier, David Joulin
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
#  created_on       :date
#  creator_id       :integer
#  currency         :string(3)        not null
#  description      :string(255)
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  label            :string(255)
#  lock_version     :integer          default(0), not null
#  started_on       :date
#  stopped_on       :date
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class Transfer < Ekylibre::Record::Base
  attr_readonly :description
  belongs_to :client, class_name: "Entity"

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :description, :label, allow_nil: true, maximum: 255
  validates_presence_of :amount, :client, :currency
  #]VALIDATORS]
  validates_presence_of :created_on, :client

  acts_as_affairable :dealt_on => :created_on, :debit => false, :third => :client

  before_validation do
    self.created_on ||= Date.today
    # self.paid_amount = self.payment_uses.sum(:amount)||0
  end

  bookkeep(on: :nothing) do |b|
  end

  def number
    self.id.to_s
  end



end
