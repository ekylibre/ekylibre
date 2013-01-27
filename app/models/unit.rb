# -*- coding: utf-8 -*-

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
# == Table: units
#
#  base         :string(255)      
#  coefficient  :decimal(19, 10)  default(1.0), not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  label        :string(255)      not null
#  lock_version :integer          default(0), not null
#  name         :string(8)        not null
#  start        :decimal(19, 4)   default(0.0), not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Unit < CompanyRecord
  attr_accessible :base, :coefficient, :label, :name, :start
  has_many :products, :class_name => "Product"
  has_many :stock_moves, :class_name => "ProductMove"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :coefficient, :start, :allow_nil => true
  validates_length_of :name, :allow_nil => true, :maximum => 8
  validates_length_of :base, :label, :allow_nil => true, :maximum => 255
  validates_presence_of :coefficient, :label, :name, :start
  #]VALIDATORS]
  validates_format_of :name, :with => /^[a-zA-Z][a-zA-Z0-9]*([\.\/][a-zA-Z][a-zA-Z0-9]*)?$/
  validates_uniqueness_of :name
  scope :of_product, lambda { |product| where(:base => product.unit.base).order(:coefficient, :label) }

  SI_UNITS = ["m", "kg", "s", "A", "K", "mol", "cd"]

  DEFAULT_UNITS = {
    :u =>  {},
    :kg => {:base => 'kg'},
    :t =>  {:base => 'kg', :coefficient => 1000},
    :m =>  {:base => 'm'},
    :km => {:base => 'm',  :coefficient => 1000},
    :ha => {:base => 'm2', :coefficient => 10000},
    :a =>  {:base => 'm2', :coefficient => 100},
    :ca => {:base => 'm2'},
    :l =>  {:base => 'm3', :coefficient => 0.001},
    :hl => {:base => 'm3', :coefficient => 0.1},
    :m3 => {:base => 'm3'}
  }

  before_validation do
    self.name.strip!
    self.coefficient ||= 1
    self.start ||= 0
    return true
  end

  validate do
    self.base.to_s.split(/[\.\s]+/).each do |x|
      if x.match(/[a-z]+(\-\d+)?/i)
        name = x.gsub(/[0-9\-]+/, '')
        errors.add(:base, :invalid_token, :error => x.inspect, :accepted => SI_UNITS.to_sentence) unless SI_UNITS.include? name
      else
        errors.add(:base, :invalid_at, :error => x.inspect)
      end
    end
  end

  before_save do
    self.base = self.class.normalize(self.base)
  end

  def self.load_defaults
    for name, attributes in DEFAULT_UNITS
      unless self.find_by_name(name.to_s)
        self.create!(attributes.merge(:name => name.to_s, :label => tc('default.'+name.to_s)))
      end
    end
  end

  def self.normalize(expr)
    expression = expr.to_s.dup
    expression.strip!

    # flatten
    flat = expression.split(/[\.\s]+/).collect do |x|
      if x.match(/[a-z]+(\-\d+)?/i)
        name = x.gsub(/[0-9\-]+/, '')
        raise Exception.new("Unknown unit #{name.inspect} (only base units #{SI_UNITS.join(', ')} are accepted)") unless SI_UNITS.include? name
      else
        raise Exception.new("Bad expression: error on #{x.inspect}")
      end
      x
    end.join(".")

    # reduce
    exps = {}
    flat.split(/[\.\s]+/).each do |x|
      name = x.gsub(/[0-9\-]+/,'')
      exps[name] = (exps[name]||0)+(x == name ? 1 : x.gsub(/[a-z]+/i, '').to_i)
    end

    # magnify
    exps.sort.collect{|k,v| k+(v!=1 ? v.to_s : "") if v != 0}.compact.join(".")
  end

  def readable_name
    self.name.gsub('2', '²').gsub('3', '³')
  end

  def self.convert(measure, from, to=nil)
    return measure if to and to.id == from.id
    # basic = (measure.to_f-from.base.to_f) / from.coefficient.to_f
    basic = measure.to_f*from.coefficient.to_f+from.base.to_f
    return basic if to.nil?
    raise Exception.new("The dimensions of the units #{from.label} and #{to.label} are incompatible!") unless from.convertible_to? to
    return (basic-to.base.to_f)/to.coefficient.to_f
  end

  # Convert a measure from the associated unit to self
  def convert_from(measure, unit)
    self.class.convert(measure, unit, self)
  end

  # Convert a measure from the associated unit to self
  def convert(measure, unit)
    self.class.convert(measure, unit, self)
  end

  # Convert a measure from self to the associated unit
  def convert_to(measure, unit=nil)
    self.class.convert(measure, self, unit)
  end

  def convertible_to?(other_unit)
    return (self.base == other_unit.base ? true : false)
  end

  protect(:on => :destroy) do
    return false
  end

end
