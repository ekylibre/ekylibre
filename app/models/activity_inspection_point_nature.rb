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
# == Table: activity_inspection_point_natures
#
#  activity_id  :integer          not null
#  category     :string           not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string           not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

class ActivityInspectionPointNature < Ekylibre::Record::Base
  belongs_to :activity
  enumerize :category, in: %i[disease deformity none], default: :none, predicates: true
  has_many :inspection_points, inverse_of: :nature, foreign_key: :nature_id, dependent: :restrict_with_exception
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :activity, :category, presence: true
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :name, uniqueness: { scope: :activity_id }

  scope :unmarketable, -> { where.not(category: 'none') }

  def self.unmarketable_categories
    category.values - ['none']
  end
end
