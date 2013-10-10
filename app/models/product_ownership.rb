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
# == Table: product_ownerships
#
#  created_at        :datetime         not null
#  creator_id        :integer
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  move_id           :integer
#  move_type         :string(255)
#  nature            :string(255)      not null
#  operation_task_id :integer
#  owner_id          :integer
#  product_id        :integer          not null
#  started_at        :datetime
#  stopped_at        :datetime
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class ProductOwnership < Ekylibre::Record::Base
  belongs_to :owner, :class_name => "Entity"
  belongs_to :product
  belongs_to :operation_task
  enumerize :nature, :in => [:unknown, :own, :other], :default => :unknown, :predicates => true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :move_type, :nature, :allow_nil => true, :maximum => 255
  validates_presence_of :nature, :product
  #]VALIDATORS]

  before_validation do
    self.nature = (self.owner.blank? ? :unknown : (self.owner == Entity.of_company) ? :own : :other)
  end

  def move_to(owner,moved_at = Time.now)
    self.class.transaction do
      self.class.create!(owner: owner, product_id: self.product_id, started_at: moved_at, stopped_at: self.stopped_at)
      self.stopped_at = moved_at
      self.save!
    end
  end



end
