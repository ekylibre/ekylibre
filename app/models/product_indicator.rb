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
# == Table: product_indicators
#
#  active         :boolean          not null
#  created_at     :datetime         not null
#  creator_id     :integer
#  description    :text
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  maximal_length :integer
#  maximal_value  :decimal(19, 4)
#  minimal_length :integer
#  minimal_value  :decimal(19, 4)
#  name           :string(255)      not null
#  nature         :string(255)      not null
#  process_id     :integer
#  unit_id        :integer
#  updated_at     :datetime         not null
#  updater_id     :integer
#  usage          :string(255)
#


class ProductIndicator < Ekylibre::Record::Base
  attr_accessible :product_nature_id, :created_at, :description, :name, :nature, :active, :choices_attributes, :process_id , :unit_id , :usage, :maximal_length, :minimal_length, :maximal_value, :minimal_value
  attr_readonly :nature
  enumerize :nature, :in => [:string, :decimal, :boolean, :measure, :choice], :predicates => true
  enumerize :usage, :in => [:life, :production, :environment]
  belongs_to :process, :class_name => "ProductProcess"
  belongs_to :product_nature, :class_name => "ProductNature"
  belongs_to :unit, :class_name => "Unit"
  has_many :data, :class_name => "ProductIndicatorDatum", :foreign_key => :indicator_id, :dependent => :delete_all, :inverse_of => :indicator
  has_many :choices, :class_name => "ProductIndicatorChoice", :foreign_key => :indicator_id, :order => :position, :dependent => :delete_all, :inverse_of => :indicator

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :maximal_length, :minimal_length, :allow_nil => true, :only_integer => true
  validates_numericality_of :maximal_value, :minimal_value, :allow_nil => true
  validates_length_of :name, :nature, :usage, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :in => [true, false]
  validates_presence_of :name, :nature
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values
  validates_inclusion_of :usage, :in => self.usage.values

  accepts_nested_attributes_for :choices

  default_scope -> { order(:name) }
  scope :actives, -> { where(:active => true).order(:name) }

  def choices_count
    self.choices.count
  end

  def sort_choices!
    self.choices.reorder(:name).to_a.each_with_index do |choice, index|
      choice.position = index + 1
      choice.save!
    end
  end

end
