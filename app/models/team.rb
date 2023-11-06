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
# == Table: teams
#
#  created_at              :datetime         not null
#  creator_id              :integer(4)
#  depth                   :integer(4)       default(0), not null
#  description             :text
#  id                      :integer(4)       not null, primary key
#  isacompta_analytic_code :string(2)
#  lft                     :integer(4)
#  lock_version            :integer(4)       default(0), not null
#  name                    :string           not null
#  parent_id               :integer(4)
#  rgt                     :integer(4)
#  updated_at              :datetime         not null
#  updater_id              :integer(4)
#

class Team < ApplicationRecord
  has_many :employees, class_name: 'User'
  has_many :projects
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :depth, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :isacompta_analytic_code, length: { maximum: 2 }, allow_blank: true
  validates :lft, :rgt, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :name, uniqueness: true
  validates_length_of :isacompta_analytic_code, is: 2, if: :isacompta_analytic_code?

  acts_as_nested_set
end
