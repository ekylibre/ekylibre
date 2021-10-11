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
# == Table: idea_diagnostics
#
#  auditor_id   :integer          not null
#  campaign_id  :integer
#  code         :string
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string
#  state        :string
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class IdeaDiagnostic < ApplicationRecord
  enumerize :state, in: %i[idea_doing done], default: :idea_doing, predicates: true
  has_many :idea_diagnostic_items, dependent: :destroy
  has_one :idea_diagnostic_result, dependent: :destroy
  belongs_to :auditor, class_name: 'Entity'
  belongs_to :campaign

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :name, presence: true, length: { maximum: 500 }
  validates :auditor, presence: true
  validates :campaign, presence: true
  validates :campaign_id, uniqueness: { message: :unicity_by_campaign }

  # ]VALIDATORS]
  before_validation :set_default_values

  private

    def set_default_values
      if self.campaign
        self.code = "IDEA#{Campaign.find_by_id(self.campaign).name}"
        self.name = "#{:idea_diagnostic.tl} #{Campaign.find_by_id(self.campaign).name}" if self.name.blank?
      end
    end

end
