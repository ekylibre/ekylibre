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
# == Table: procedures
#
#  created_at    :datetime         not null
#  creator_id    :integer
#  id            :integer          not null, primary key
#  incident_id   :integer
#  lock_version  :integer          default(0), not null
#  nomen         :string(255)      not null
#  production_id :integer          not null
#  state         :string(255)      default("undone"), not null
#  updated_at    :datetime         not null
#  updater_id    :integer
#
class Procedure < Ekylibre::Record::Base
  attr_accessible :nomen, :activity_id, :campaign_id
  attr_readonly :nomen, :activity_id, :campaign_id
  belongs_to :production
  belongs_to :incident
  has_many :variables, :class_name => "ProcedureVariable", :inverse_of => :procedure
  has_many :operations, :inverse_of => :procedure
  enumerize :nomen, :in => Procedures.names.sort
  enumerize :state, :in => [:undone, :squeezed, :in_progress, :done]
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nomen, :state, :allow_nil => true, :maximum => 255
  validates_presence_of :nomen, :production, :state
  #]VALIDATORS]
  validates_inclusion_of :nomen, :in => self.nomen.values
  validates_presence_of :version, :uid

  before_validation(:on => :create) do
    unless self.root?
      if root = self.root
        self.activity = root.activity
        self.campaign = root.campaign
        self.incident = root.incident
      end
    end
    if self.root?
      self.uid ||= Procedures[self.nomen.to_s].id
    end
    if self.reference
      self.version = self.reference.version
      self.uid = self.reference.id
    end
    if self.children.where(:state => ["undone", "in_progress"]).count > 0 or self.children.count != self.reference.children.size
      self.state = "in_progress"
    else self.children.count.zero? or self.children.where(:state => ["undone", "in_progress"]).count.zero?
      self.state = "done"
    end
  end

  # Reference
  def reference
    ref.hash[self.uid]
  end

  # Main reference
  def ref
    Procedures[self.root.nomen.to_s]
  end

  # Returns variable names
  def variables_names
    self.variables.map(&:target_name).sort.to_sentence
  end

  def name
    self.root.reference.hash[self.uid].human_name
  end

  # Return the next procedure (depth course)
  def followings
    reference.followings_of(self.uid)
  end

  def playing
    return self.root.playing unless self.root
    for p in ref.tree
      if self.children.where(:uid => p.id)
      end
    end
  end

  def get(refp)
    return self.root.get(refp) unless self.root?
    return self.children.where(:uid => refp.id).first
  end


  # Create a procedure from the reference with given refp
  def load(refp, state = :undone)
    return self.root.load(refp, state) unless self.root?
    raise "What this proc?" unless refp.parent
    parent = self.self_and_descendants.where(:uid => refp.parent.id).first || self.load(refp.parent)
    unless p = self.self_and_descendants.where(:uid => refp.id).first
      p = self.class.create!({:parent_id => parent.id, :nomen => refp.name.to_s, :state => state, :version => refp.version, :uid => refp.id}, :without_protection => true)
    end
    return p
  end

  # Set a procedure as squeezed
  def squeeze(refp)
    load(refp, :squeezed)
  end

end
