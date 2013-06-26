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
# == Table: incidents
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  gravity      :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(255)      not null
#  observed_at  :datetime         not null
#  priority     :integer
#  state        :string(255)
#  target_id    :integer          not null
#  target_type  :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Incident < Ekylibre::Record::Base
  attr_accessible :name, :nature, :observed_at, :description, :priority, :gravity, :target_id, :target_type
  enumerize :nature, :in => Nomen::Incidents.all, :default => Nomen::Incidents.default, :predicates => {:prefix => true}
  has_many :procedures, :class_name => "Procedure"
  belongs_to :target , :polymorphic => true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :gravity, :priority, :allow_nil => true, :only_integer => true
  validates_length_of :name, :nature, :state, :target_type, :allow_nil => true, :maximum => 255
  validates_presence_of :name, :nature, :observed_at, :target, :target_type
  #]VALIDATORS]
  validates_inclusion_of :priority, :in => 0..5
  validates_inclusion_of :priority, :in => 0..5

    state_machine :state, :initial => :new do
      state :new
      state :in_progress
      state :closed

      event :treated do
        transition :new => :in_progress, :if => :has_procedure?
      end
    end

  def has_procedure?
    self.procedures.count > 0
  end

end
