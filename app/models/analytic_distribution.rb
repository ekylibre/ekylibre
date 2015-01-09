# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: analytic_distributions
#
#  affectation_percentage :decimal(19, 4)   not null
#  affected_at            :datetime         not null
#  created_at             :datetime         not null
#  creator_id             :integer
#  id                     :integer          not null, primary key
#  journal_entry_item_id  :integer          not null
#  lock_version           :integer          default(0), not null
#  production_id          :integer          not null
#  state                  :string(255)      not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#

class AnalyticDistribution < Ekylibre::Record::Base
  enumerize :state, in: [:draft, :confirmed, :closed], default: :draft

  belongs_to :production
  belongs_to :journal_entry_item


  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :affected_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :affectation_percentage, allow_nil: true
  validates_length_of :state, allow_nil: true, maximum: 255
  validates_presence_of :affectation_percentage, :affected_at, :journal_entry_item, :production, :state
  #]VALIDATORS]

  # state_machine :state, :initial => :draft do
  #   state :draft
  #   state :confirmed
  #   state :closed
  # end

end
