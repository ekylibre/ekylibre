# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: activity_repartitions
#
#  activity_id           :integer          not null
#  affected_on           :date             not null
#  campaign_id           :integer
#  created_at            :datetime         not null
#  creator_id            :integer
#  description           :text
#  id                    :integer          not null, primary key
#  journal_entry_item_id :integer          not null
#  lock_version          :integer          default(0), not null
#  percentage            :decimal(19, 4)   not null
#  product_nature_id     :integer
#  state                 :string(255)      not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#
class ActivityRepartition < Ekylibre::Record::Base
  attr_accessible :state, :activity_id, :affected_on, :campaign_id, :description, :journal_entry_item_id, :product_nature_id, :percentage
  belongs_to :activity
  belongs_to :campaign
  belongs_to :product_nature
  belongs_to :journal_entry_item

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :percentage, :allow_nil => true
  validates_length_of :state, :allow_nil => true, :maximum => 255
  validates_presence_of :activity, :affected_on, :journal_entry_item, :percentage, :state
  #]VALIDATORS]

  state_machine :state, :initial => :draft do
    state :draft
    state :confirmed
    state :closed
  end

  default_scope -> { order(:name) }


end
