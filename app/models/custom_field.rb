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
# == Table: custom_fields
#
#  active          :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  customized_type :string(255)      not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  maximal_length  :integer
#  maximal_value   :decimal(19, 4)
#  minimal_length  :integer          default(0), not null
#  minimal_value   :decimal(19, 4)
#  name            :string(255)      not null
#  nature          :string(8)        not null
#  position        :integer
#  required        :boolean          not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#


class CustomField < Ekylibre::Record::Base
  acts_as_list :scope => 'customized_type = \'#{customized_type}\''
  attr_accessible :active, :maximal_length, :minimal_length, :maximal_value, :minimal_value, :name, :nature, :position, :required, :customized_type
  attr_readonly :nature
  enumerize :nature, :in => [:string, :decimal, :boolean, :date, :datetime, :choice], :predicates => true
  enumerize :customized_type, :in => Ekylibre.models.map(&:to_s).map(&:camelcase), :default_value => Ekylibre.models.first, :predicates => {:prefix => true}
  has_many :choices, :class_name => "CustomFieldChoice", :order => :position, :dependent => :delete_all, :inverse_of => :custom_field
  has_many :data, :class_name => "CustomFieldDatum", :dependent => :delete_all, :inverse_of => :custom_field
  #[VALIDATORS[ Do not edit these items directly. Use `rake clean:validations`.
  validates_numericality_of :maximal_length, :minimal_length, :allow_nil => true, :only_integer => true
  validates_numericality_of :maximal_value, :minimal_value, :allow_nil => true
  validates_length_of :nature, :allow_nil => true, :maximum => 8
  validates_length_of :customized_type, :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :required, :in => [true, false]
  validates_presence_of :customized_type, :minimal_length, :name, :nature
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values
  validates_inclusion_of :customized_type, :in => self.customized_type.values

  accepts_nested_attributes_for :choices

  default_scope -> { order(:customized_type, :position) }
  scope :actives, -> { where(:active => true).order(:position) }
  scope :of, lambda { |model| where(:active => true, :customized_type => model) }

  def choices_count
    self.choices.count
  end

  def sort_choices
    self.choices.order(:name).to_a.each_with_index do |choice, index|
      choice.position = index + 1
      choice.save!
    end
  end

end
