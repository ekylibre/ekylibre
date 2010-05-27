# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
#  company_id     :integer          not null
#  consumption    :decimal(, )      
#  created_at     :datetime         not null
#  creator_id     :integer          
#  description    :text             
#  duration       :decimal(, )      
#  hour_duration  :decimal(, )      
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  min_duration   :decimal(, )      
#  moved_on       :date             
#  name           :string(255)      not null
#  nature_id      :integer          
#  planned_on     :date             not null
#  responsible_id :integer          not null
#  started_at     :datetime         not null
#  stopped_at     :datetime         
#  target_id      :integer          
#  target_type    :string(255)      
#  tools_list     :string(255)      
#  updated_at     :datetime         not null
#  updater_id     :integer          
#

class Operation < ActiveRecord::Base
  belongs_to :company
  belongs_to :nature, :class_name=>OperationNature.name
  belongs_to :responsible, :class_name=>User.name
  belongs_to :target, :polymorphic=>true
  has_many :tool_uses, :dependent=>:destroy
  has_many :uses,  :class_name=>ToolUse.name, :dependent=>:destroy
  has_many :lines, :class_name=>OperationLine.name, :dependent=>:destroy
  has_many :tools, :through=>:tool_uses

  attr_readonly :company_id
 
  def before_validation_on_create
    self.started_at = Time.now if self.started_at.nil?
  end

  def before_validation
    self.duration = (self.min_duration.to_i + (self.hour_duration.to_i)*60 )
  end


  def save_with_uses_and_lines(uses=[], lines=[])
    ActiveRecord::Base.transaction do
      saved = self.save
      # Tools
      self.uses.clear
      uses.each_index do |index|
        uses[index] = self.uses.build(uses[index])
        #if saved
          saved = false unless uses[index].save
        #end
      end
      if saved
        self.reload
        self.update_attribute(:tools_list, self.tools.collect{|t| t.name}.to_sentence)
      end
      
      # Lines
      self.lines.clear
      lines.each_index do |index|
        lines[index] = self.lines.build(lines[index])
        #if saved
          saved = false unless lines[index].save
        #end
      end
      self.reload if saved
#       self.entries.clear
#       entries.each_index do |index|
#         entries[index] = self.entries.build(entries[index])
#         if saved
#           saved = false unless entries[index].save
#         end
#       end
#       self.reload if saved
#       if saved and not self.balanced?
#         self.errors.add_to_base(:unbalanced) 
#         saved = false
#       end
      if saved
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    return false
  end

  def set_tools(tools)
    # Reinit tool uses
    self.tool_uses.clear
    # Add new tools
    unless tools.nil?
      tools.each do |tool|
        self.company.tool_uses.create!(:operation_id=>self.id, :tool_id=>tool[0].to_i)
      end
    end
    self.reload
    self.tools_list = self.tools.collect{|t| t.name}.join(", ")
    self.save
  end


  # Set all the lines in one time 
  def set_lines(lines)
    # Reinit stock if existing lines
    self.lines.clear
    # Reload (new) values
    for line in lines
      self.lines.create!(line)
    end
    return true
  end

  def make(made_on)
    ActiveRecord::Base.transaction do
      for line in lines
        # line.product.add_stock_move(:virtual=>false, :incoming=>line.out?, :origin=>line)
        line.product.move_stock(:incoming=>line.out?, :origin=>line)
      end
      self.update_attributes!(:moved_on=>made_on) 
    end
  end

end

