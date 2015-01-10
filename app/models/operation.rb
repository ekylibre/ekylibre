# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
#  company_id                      :integer          not null
#  consumption                     :decimal(16, 4)   
#  created_at                      :datetime         not null
#  creator_id                      :integer          
#  description                     :text             
#  duration                        :decimal(16, 4)   
#  hour_duration                   :decimal(16, 4)   
#  id                              :integer          not null, primary key
#  lock_version                    :integer          default(0), not null
#  min_duration                    :decimal(16, 4)   
#  moved_on                        :date             
#  name                            :string(255)      not null
#  nature_id                       :integer          
#  planned_on                      :date             not null
#  production_chain_work_center_id :integer          
#  responsible_id                  :integer          not null
#  started_at                      :datetime         not null
#  stopped_at                      :datetime         
#  target_id                       :integer          
#  target_type                     :string(255)      
#  tools_list                      :string(255)      
#  updated_at                      :datetime         not null
#  updater_id                      :integer          
#


class Operation < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :consumption, :duration, :hour_duration, :min_duration, :allow_nil => true
  validates_length_of :name, :target_type, :tools_list, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  belongs_to :company
  belongs_to :nature, :class_name=>"OperationNature"
  belongs_to :responsible, :class_name=>"User"
  belongs_to :target, :polymorphic=>true
  belongs_to :production_chain_work_center
  has_many :operation_uses, :dependent=>:destroy
  has_many :uses,  :class_name=>"OperationUse", :dependent=>:destroy
  has_many :lines, :class_name=>"OperationLine", :dependent=>:destroy
  has_many :tools, :through=>:operation_uses

  attr_readonly :company_id
 
  before_validation(:on=>:create) do
    self.company_id = self.production_chain_work_center.company_id if self.production_chain_work_center
    self.started_at = Time.now if self.started_at.nil?
  end

  before_validation do
    self.duration = (self.min_duration.to_i + (self.hour_duration.to_i)*60 )
  end


  def save_with_uses_and_lines(uses=[], lines=[])
    ActiveRecord::Base.transaction do
      op_saved = self.save
      saved = op_saved
      # Tools
      self.uses.clear
      uses.each_index do |index|
        uses[index] = self.uses.build(uses[index])
        if op_saved
          saved = false unless uses[index].save
        end
      end
      if saved
        self.reload
        self.update_attribute(:tools_list, self.tools.collect{|t| t.name}.to_sentence)
      end
        
      # Lines
      self.lines.clear
      lines.each_index do |index|
        lines[index] = self.lines.build(lines[index])
        if op_saved
          saved = false unless lines[index].save
        end
      end
      self.reload if saved
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
    self.operation_uses.clear
    # Add new tools
    unless tools.nil?
      tools.each do |tool|
        self.company.operation_uses.create!(:operation_id=>self.id, :tool_id=>tool[0].to_i)
      end
    end
    self.reload
    self.tools_list = self.tools.collect{|t| t.name}.join(", ")
    self.save
  end


  # Set all the lines in one time 
  def set_lines(lines)
    # Reinit existing lines
    self.lines.clear
    # Reload (new) values
    for line in lines
      self.lines.create!(line)
    end
    return true
  end

  def make(made_on)
    ActiveRecord::Base.transaction do
      self.update_attributes!(:moved_on=>made_on)
      for line in lines
        line.confirm_stock_move
      end
    end
  end

  protect_on_update do
    self.production_chain_work_center.nil?
  end

end

