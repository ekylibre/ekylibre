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
# == Table: gaps
#
#  accounted_at     :datetime
#  affair_id        :integer
#  amount           :decimal(19, 4)   default(0.0), not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string           not null
#  direction        :string           not null
#  entity_id        :integer          not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  number           :string           not null
#  pretax_amount    :decimal(19, 4)   default(0.0), not null
#  printed_at       :datetime         not null
#  type             :string
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class Gap < Ekylibre::Record::Base
  enumerize :direction, in: %i[profit loss], predicates: true
  refers_to :currency
  belongs_to :affair, inverse_of: :gaps
  belongs_to :entity
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :third, foreign_key: :entity_id, class_name: 'Entity' # alias for entity
  has_many :items, class_name: 'GapItem', inverse_of: :gap, dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, :direction, :entity, :third, presence: true
  validates :number, presence: true, length: { maximum: 500 }
  validates :printed_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  # No Gap can be registered, only subclasses because role is needed
  validates :type,  exclusion: { in: [Gap.name], message: :invalid }

  acts_as_numbered
  alias_attribute :label, :number

  before_validation do
    self.printed_at ||= Time.zone.now
  end

  def printed_on
    printed_at.to_date
  end

  def loss_coefficient
    loss? ? -1 : 1
  end

  def relative_amount
    loss_coefficient * amount
  end
  alias deal_amount relative_amount
end
