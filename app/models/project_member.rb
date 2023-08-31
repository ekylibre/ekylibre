# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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
# == Table: project_members
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  project_id   :integer          not null
#  role         :string
#  updated_at   :datetime         not null
#  updater_id   :integer
#  user_id      :integer          not null
#
class ProjectMember < ApplicationRecord
  belongs_to :project, inverse_of: :members
  belongs_to :user
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :role, length: { maximum: 500 }, allow_blank: true
  validates :project, :user, presence: true
  # ]VALIDATORS]
end
