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
  # attr_accessible :started_at, :stopped_at, :procedure_id # :nature
  belongs_to :intervention
  has_many :tasks, class_name: "OperationTask"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :duration, :allow_nil => true, :only_integer => true
  validates_presence_of :intervention, :started_at, :stopped_at
  #]VALIDATORS]

  # default_scope -> { order(:started_at) }
  scope :unvalidateds, -> { where(:confirmed => false) }

  before_validation(:on => :create) do
    self.started_at ||= Time.now
    if self.started_at and self.stopped_at
      self.duration = (self.stopped_at - self.started_at).to_i
    end
  end

  after_save do
    self.intervention.save!
  end

  # def save_with_uses_and_items(uses=[], items=[])
  #   ActiveRecord::Base.transaction do
  #     op_saved = self.save
  #     saved = op_saved
  #     # Equipments
  #     self.uses.clear
  #     uses.each_index do |index|
  #       uses[index] = self.uses.build(uses[index])
  #       if op_saved
  #         saved = false unless uses[index].save
  #       end
  #     end
  #     if saved
  #       self.reload
  #       self.update_column(:equipments_list, self.equipments.collect{|t| t.name}.to_sentence)
  #     end

  #     # Items
  #     self.items.clear
  #     items.each_index do |index|
  #       items[index] = self.items.build(items[index])
  #       if op_saved
  #         saved = false unless items[index].save
  #       end
  #     end
  #     self.reload if saved
  #     if saved
  #       return true
  #     else
  #       raise ActiveRecord::Rollback
  #     end
  #   end
  #   return false
  # end

  # def set_equipments(equipments)
  #   # Reinit equipment uses
  #   self.operation_uses.clear
  #   # Add new equipments
  #   unless equipments.nil?
  #     equipments.each do |equipment|
  #       OperationUse.create!(:operation_id => self.id, :equipment_id => equipment[0].to_i)
  #     end
  #   end
  #   self.reload
  #   self.equipments_list = self.equipments.collect{|t| t.name}.join(", ")
  #   self.save
  # end


  # # Set.all the items in one time
  # def set_items(items)
  #   # Reinit existing items
  #   self.items.clear
  #   # Reload (new) values
  #   for item in items
  #     self.items.create!(item)
  #   end
  #   return true
  # end

  def make(made_on)
    ActiveRecord::Base.transaction do
      self.update_attributes!(:moved_on => made_on)
      for item in items
        item.confirm_stock_move
      end
    end
  end

end

