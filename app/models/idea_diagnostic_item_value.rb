# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: idea_diagnostic_item_values
#
#  id                      :integer          not null, primary key
#  idea_diagnostic_item_id :integer
#
class IdeaDiagnosticItemValue < ApplicationRecord
  belongs_to :idea_diagnostic_item
  validates :nature, presence: true
  validates :boolean_value, inclusion: { in: [true, false] }, allow_blank: true
  validates :float_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :integer_value, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :string_value, length: { maximum: 500_000 }, allow_blank: true
  validates :nature, inclusion: { in: %w[boolean integer float string] }

  # Find and set preference with given value
  def set!(value, nature)
    self.update!(nature: nature)
    self.update!(value_attribute => value)
  end

  # Returns item value
  def value
    send(value_attribute)
  end

  private

    # Returns the name of the column used to store ItemValue data
    def value_attribute
      "#{nature}_value"
    end

end
