# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: intervention_participations
#
#  created_at        :datetime         not null
#  creator_id        :integer
#  id                :integer          not null, primary key
#  intervention_id   :integer
#  lock_version      :integer          default(0), not null
#  product_id        :integer
#  request_compliant :boolean          default(FALSE), not null
#  state             :string
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class InterventionParticipation < Ekylibre::Record::Base
  belongs_to :intervention
  belongs_to :product

  has_many :working_periods, class_name: 'InterventionWorkingPeriod', dependent: :destroy
  has_many :crumbs, dependent: :destroy

  validates :product_id, presence: true
  validates :intervention_id, uniqueness: { scope: [:product_id] }, unless: -> { intervention_id.blank? }
  validates :state, presence: true
  enumerize :state, in: [:in_progress, :done, :validated]
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :request_compliant, inclusion: { in: [true, false] }
  # ]VALIDATORS]

  before_save do
    if intervention.present?
      intervention.update_state(id => state)
      intervention.update_compliance(id => request_compliant)
    end
  end

  scope :unprompted, -> { where(intervention_id: nil) }
end
