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
# == Table: interventions
#
#  created_at                  :datetime         not null
#  creator_id                  :integer
#  id                          :integer          not null, primary key
#  incident_id                 :integer
#  lock_version                :integer          default(0), not null
#  natures                     :string(255)      not null
#  prescription_id             :integer
#  procedure                   :string(255)      not null
#  production_id               :integer          not null
#  provisional                 :boolean          not null
#  provisional_intervention_id :integer
#  started_at                  :datetime
#  state                       :string(255)      not null
#  stopped_at                  :datetime
#  updated_at                  :datetime         not null
#  updater_id                  :integer
#

class Intervention < Ekylibre::Record::Base
  # attr_accessible :nomen, :production_id, :state, :natures, :provisional_procedure_id, :provisional, :prescription_id, :incident_id
  attr_readonly :procedure, :production_id
  belongs_to :production
  belongs_to :incident
  belongs_to :prescription
  belongs_to :provisional_intervention, class_name: "Intervention"
  has_many :casts, :class_name => "InterventionCast", :inverse_of => :intervention
  has_many :operations, :inverse_of => :intervention
  enumerize :procedure, :in => Procedures.names.sort
  enumerize :state, :in => [:undone, :squeezed, :in_progress, :done], :default => :undone
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :natures, :procedure, :state, :allow_nil => true, :maximum => 255
  validates_inclusion_of :provisional, :in => [true, false]
  validates_presence_of :natures, :procedure, :production, :state
  #]VALIDATORS]
  validates_inclusion_of :procedure, :in => self.procedure.values
  #validates_presence_of :version, :uid

  # @TODO in progress - need to .all parent procedure to have the name of the procedure_nature

  scope :of_nature, lambda { |*natures|
    where("natures ~ E?", natures.sort.map { |nature| "\\\\m#{nature.to_s.gsub(/\W/, '')}\\\\M" }.join(".*"))
  }
  # scope :of_nature, lambda { |nature|
  #   raise ArgumentError.new("Unknown nature #{nature.inspect}") unless Nomen::ProcedureNatures[nature]
  #   where("natures ~ E?", "\\\\m#{nature}\\\\M")
  # }
  scope :provisional, -> { where(:provisional => true).order(:nomen) }
  scope :real, -> { where(:provisional => false).order(:nomen) }

  scope :with_variable, lambda { |role, object|
     where("id IN (SELECT intervention_id FROM #{InterventionCast.table_name} WHERE actor_id = ? AND role = ?)", object.id, role.to_s)
  }

  before_validation do
    self.state ||= self.class.state.default
    self.natures = self.natures.to_s.strip.split(/[\s\,]+/).sort.join(" ")
  end

  # before_validation(:on => :create) do
  #   unless self.root?
  #     if root = self.root
  #       self.activity = root.activity
  #       self.campaign = root.campaign
  #       self.incident = root.incident
  #     end
  #   end
  #   if self.root?
  #     self.uid ||= Procedures[self.nomen.to_s].id
  #   end
  #   if self.reference
  #     self.version = self.reference.version
  #     self.uid = self.reference.id
  #   end
  #   if self.children.where(:state => ["undone", "in_progress"]).count > 0 or self.children.count != self.reference.children.size
  #     self.state = "in_progress"
  #   else self.children.count.zero? or self.children.where(:state => ["undone", "in_progress"]).count.zero?
  #     self.state = "done"
  #   end
  # end


  # started_at (the first operation of the current procedure)
  def started_at
    if operation = self.operations.reorder(:started_at).first
      return operation.started_at
    end
    return nil
  end

  def stopped_at
    if operation = self.operations.reorder(:stopped_at).first
      return operation.stopped_at
    end
    return nil
  end

  # Reference
  def reference
    #  ref.hash[self.uid]
    self.nomen
  end

  # Main reference
  def ref
    Procedures[self.nomen.to_s]
  end

  # Returns variable names
  def variables_names
    self.variables.map(&:target_name).sort.to_sentence
  end

  def name
    ref.human_name
  end

  # # Return the next procedure (depth course)
  # def followings
  #   reference.followings_of(self.uid)
  # end

  # def playing
  #   return self.root.playing unless self.root
  #   for p in ref.tree
  #     if self.children.where(:uid => p.id)
  #     end
  #   end
  # end

  # def get(refp)
  #   return self.root.get(refp) unless self.root?
  #   return self.children.where(:uid => refp.id).first
  # end


  # # Create a procedure from the reference with given refp
  # def load(refp, state = :undone)
  #   return self.root.load(refp, state) unless self.root?
  #   raise "What this proc?" unless refp.parent
  #   parent = self.self_and_descendants.where(:uid => refp.parent.id).first || self.load(refp.parent)
  #   unless p = self.self_and_descendants.where(:uid => refp.id).first
  #     p = self.class.create!({:parent_id => parent.id, :nomen => refp.name.to_s, :state => state, :version => refp.version, :uid => refp.id}, :without_protection => true)
  #   end
  #   return p
  # end

  # # Set a procedure as squeezed
  # def squeeze(refp)
  #   load(refp, :squeezed)
  # end

end
