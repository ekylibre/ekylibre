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
# == Table: tasks
#
#  created_at          :datetime         not null
#  creator_id          :integer
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
  include Versionable, Commentable
  enumerize :state, in: [:todo, :doing, :done], default: :todo, predicates: true
  enumerize :nature, in: [:incoming_call, :outgoing_call, :incoming_mail, :outgoing_mail, :incoming_email, :outgoing_email, :quote, :document], default: :outgoing_call, predicates: true
  belongs_to :entity
  belongs_to :sale_opportunity
  belongs_to :executor, -> { responsibles }, class_name: "Entity"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :due_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_presence_of :due_at, :entity, :name, :nature, :state
  #]VALIDATORS]
  versionize

  state_machine :state, :initial => :todo do
    state :todo
    state :doing
    state :done

    event :reset do
      transition :doing => :todo
      transition :done => :todo
    end

    event :start do
      transition :todo => :doing
      transition :done => :doing
    end

    event :finish do
      transition :todo => :done
      transition :doing => :done
    end
  end

  before_validation(on: :create) do
    self.state ||= :todo
  end

  def call?
    self.incoming_call? or self.outgoing_call?
  end

  def mail?
    self.incoming_mail? or self.outgoing_mail?
  end

  def email?
    self.incoming_email? or self.outgoing_email?
  end

  def status
    return :go if self.done?
    return :caution if self.doing?
    return :stop if self.todo?
  end
end
