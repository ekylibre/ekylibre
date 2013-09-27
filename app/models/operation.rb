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
# == Table: operations
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  duration        :integer
#  id              :integer          not null, primary key
#  intervention_id :integer          not null
#  lock_version    :integer          default(0), not null
#  position        :integer
#  started_at      :datetime         not null
#  stopped_at      :datetime         not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#


class Operation < Ekylibre::Record::Base
  belongs_to :intervention, inverse_of: :operations
  has_many :tasks, class_name: "OperationTask"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :duration, :allow_nil => true, :only_integer => true
  validates_presence_of :intervention, :started_at, :stopped_at
  #]VALIDATORS]

  # default_scope -> { order(:started_at) }
  scope :unvalidateds, -> { where(:confirmed => false) }

  before_validation(:on => :create) do
    self.started_at ||= Time.now
    # TODO Remove following line!!!
    self.stopped_at ||= self.started_at
    if self.started_at and self.stopped_at
      self.duration = (self.stopped_at - self.started_at).to_i
    end
  end

  after_save do
    self.intervention.save!
  end

  def reference
    self.intervention.reference.operations[self.position]
  end

end

