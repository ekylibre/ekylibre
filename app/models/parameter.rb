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
# == Table: parameters
#
#  boolean_value     :boolean          
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  decimal_value     :decimal(16, 4)   
#  id                :integer          not null, primary key
#  integer_value     :integer          
#  lock_version      :integer          default(0), not null
#  name              :string(255)      not null
#  nature            :string(8)        default("u"), not null
#  record_value_id   :integer          
#  record_value_type :string(255)      
#  string_value      :text             
#  updated_at        :datetime         not null
#  updater_id        :integer          
#  user_id           :integer          
#

# -*- coding: utf-8 -*-
class Parameter < ActiveRecord::Base
  @@natures = Parameter.columns_hash.keys.select{|x| x.match(/_value(_id)?$/)}.collect{|x| x.split(/_value/)[0] }
  @@conversions = {:float=>'decimal', :true_class=>'boolean', :false_class=>'boolean', :fixnum=>'integer'}
  attr_readonly :company_id, :user_id, :name, :nature
  belongs_to :company
  belongs_to :user
  belongs_to :record_value, :polymorphic=>true
  cattr_reader :reference
  validates_inclusion_of :nature, :in => @@natures
  validates_uniqueness_of :name, :scope=>[:company_id, :user_id]


  def before_validation
    self.company_id = self.user.company_id if self.user
  end

  def value
    self.send(self.nature+'_value')
  end

  def value=(object)
    if @@reference[self.name]
      self.nature = @@reference[self.name][:nature] 
      self.record_value_type = @@reference[self.name][:model].name if @@reference[self.name][:model]
    end
    if self.nature == 'record' and object.class.name != self.record_value_type
      begin
        self.send(self.nature.to_s+'_value=', self.record_value_type.constantize.find(object.to_i))
      rescue  
        self.record_value_id = nil
      end
    else
      raise Exception.new([self, object.inspect]) unless @@natures.include? self.nature
      self.send(self[:nature].to_s+'_value=', object)
    end
  end

  def set(object)
    self.value = object
    self.save
  end

  def record?
    self.nature == 'record'
  end

  def self.tree_reference
    ref = {}
    for k, v in @@reference.sort
      w = k.split('.')[0]
      ref[w] ||= {}
      ref[w][k] = v
    end
    ref
  end

  private

  def self.convert(nature, string)
    case nature.to_sym
    when :boolean
      (string == "true" ? true : false)
    when :integer
      string.to_i
    when :decimal
      string.to_f
    else
      string
    end
  end

  def self.initialize_reference
    @@reference = {}
    file = File.open("#{RAILS_ROOT}/config/parameters.csv", "r")
    file.each_line do |line|
      unless line.match(/\#/)
        line   = line.strip.split(",")
        param  = line[0]
        nature = line[1]
        if nature
          @@reference[param] ||= {}
          @@reference[param][:nature] = nature
          if nature == 'record'
            @@reference[param][:model] = line[2].camelcase.constantize
          else
            @@reference[param][:default] = Parameter.convert(nature, line[2])
          end
        end
      end
    end
  end

  Parameter.initialize_reference

end
