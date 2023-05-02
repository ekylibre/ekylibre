# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: economic_situations
#
#  accounting_balance          :decimal(, )
#  client_accounting_balance   :decimal(, )
#  client_trade_balance        :decimal(, )
#  created_at                  :datetime
#  creator_id                  :integer(4)
#  id                          :integer(4)       primary key
#  lock_version                :integer(4)
#  supplier_accounting_balance :decimal(, )
#  supplier_trade_balance      :decimal(, )
#  trade_balance               :decimal(, )
#  updated_at                  :datetime
#  updater_id                  :integer(4)
#
class EconomicSituation < ApplicationRecord
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounting_balance, :client_accounting_balance, :client_trade_balance, :supplier_accounting_balance, :supplier_trade_balance, :trade_balance, numericality: true, allow_blank: true
  # ]VALIDATORS]
  self.primary_key = 'id'

  belongs_to :entity, foreign_key: :id

  scope :unbalanced, -> { where('trade_balance != client_accounting_balance AND trade_balance != supplier_accounting_balance') }

  class << self
    def include?(record)
      find_by(id: record).present?
    end
  end
end
