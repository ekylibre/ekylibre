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
#  confirmed        :boolean          not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  nature           :string(255)      not null
#  operand_id       :integer
#  operand_quantity :decimal(19, 4)
#  operand_unit_id  :integer
#  started_at       :datetime         not null
#  stopped_at       :datetime         not null
#  target_id        :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class Operation < Ekylibre::Record::Base
  attr_accessible :description, :hour_duration, :min_duration, :planned_on, :nature_id, :started_at, :stopped_at, :target_id, :target_type, :responsible_id
  belongs_to :target, :class_name => "Product"
  belongs_to :operand, :class_name => "Product"
  has_many :works, :class_name => "OperationWork"

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :operand_quantity, :allow_nil => true
  validates_length_of :nature, :allow_nil => true, :maximum => 255
  validates_inclusion_of :confirmed, :in => [true, false]
  validates_presence_of :nature, :started_at, :stopped_at, :target
  #]VALIDATORS]

  accepts_nested_attributes_for :works, :reject_if => :all_blank, :allow_destroy => true

  default_scope -> { order(:planned_on, :moved_on) }
  scope :unvalidateds, -> { where(:moved_on => nil) }

  before_validation(:on => :create) do
    self.started_at = Time.now if self.started_at.nil?
  end

  before_validation do
    self.duration = (self.min_duration.to_i + (self.hour_duration.to_i)*60 )
  end

  protect(:on => :update) do
    self.production_chain_work_center.nil?
  end

  # def save_with_uses_and_items(uses=[], items=[])
  #   ActiveRecord::Base.transaction do
  #     op_saved = self.save
  #     saved = op_saved
  #     # Tools
  #     self.uses.clear
  #     uses.each_index do |index|
  #       uses[index] = self.uses.build(uses[index])
  #       if op_saved
  #         saved = false unless uses[index].save
  #       end
  #     end
  #     if saved
  #       self.reload
  #       self.update_column(:tools_list, self.tools.collect{|t| t.name}.to_sentence)
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

  # def set_tools(tools)
  #   # Reinit tool uses
  #   self.operation_uses.clear
  #   # Add new tools
  #   unless tools.nil?
  #     tools.each do |tool|
  #       OperationUse.create!(:operation_id => self.id, :tool_id => tool[0].to_i)
  #     end
  #   end
  #   self.reload
  #   self.tools_list = self.tools.collect{|t| t.name}.join(", ")
  #   self.save
  # end


  # # Set all the items in one time
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

