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
# == Table: tasks
#
#  created_at          :datetime         not null
#  creator_id          :integer
#  custom_fields       :jsonb
#  description         :text
#  due_at              :datetime         not null
#  entity_id           :integer          not null
#  executor_id         :integer
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  name                :string           not null
#  nature              :string           not null
#  sale_opportunity_id :integer
#  state               :string           not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#

class Task < Ekylibre::Record::Base
  include Attachable
  include Commentable
  include Versionable
  include Customizable
  enumerize :state, in: %i[todo doing done], default: :todo, predicates: true
  enumerize :nature, in: %i[incoming_call outgoing_call incoming_mail outgoing_mail incoming_email outgoing_email], default: :outgoing_call, predicates: true # , :quote, :document
  belongs_to :entity
  belongs_to :sale_opportunity
  belongs_to :executor, -> { responsibles }, class_name: 'Entity'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :due_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :name, presence: true, length: { maximum: 500 }
  validates :entity, :nature, :state, presence: true
  # ]VALIDATORS]
  versionize

  state_machine :state, initial: :todo do
    state :todo
    state :doing
    state :done

    event :reset do
      transition doing: :todo
      transition done: :todo
    end

    event :start do
      transition todo: :doing
      transition done: :doing
    end

    event :finish do
      transition todo: :done
      transition doing: :done
    end
  end

  before_validation(on: :create) do
    self.state ||= :todo
  end

  validate do
    errors.add(:state, :invalid) if due_at && due_at > Time.zone.now && done?
  end

  def call?
    incoming_call? || outgoing_call?
  end

  def mail?
    incoming_mail? || outgoing_mail?
  end

  def email?
    incoming_email? || outgoing_email?
  end

  def status
    return :go if done?
    return :caution if doing?
    return :stop if todo?
  end
end
