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
# == Table: supervisions
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  custom_fields   :jsonb
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  name            :string           not null
#  time_window     :integer
#  updated_at      :datetime         not null
#  updater_id      :integer
#  view_parameters :json
#
class Supervision < Ekylibre::Record::Base
  include Customizable
  has_many :items, class_name: 'SupervisionItem', dependent: :destroy, inverse_of: :supervision
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :name, presence: true, length: { maximum: 500 }
  validates :time_window, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  # ]VALIDATORS]

  accepts_nested_attributes_for :items

  before_validation do
    self.time_window ||= 240
  end

  def indicator_names
    items.map(&:indicator_names).flatten.uniq
  end
end
