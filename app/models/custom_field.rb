# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: custom_fields
#
#  active          :boolean          default(TRUE), not null
#  column_name     :string           not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  customized_type :string           not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  maximal_length  :integer
#  maximal_value   :decimal(19, 4)
#  minimal_length  :integer
#  minimal_value   :decimal(19, 4)
#  name            :string           not null
#  nature          :string           not null
#  position        :integer
#  required        :boolean          default(FALSE), not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#

class CustomField < Ekylibre::Record::Base
  attr_readonly :nature
  enumerize :nature, in: %i[text decimal boolean date datetime choice], predicates: true
  enumerize :customized_type, in: Ekylibre::Schema.model_names, i18n_scope: ['activerecord.models']
  has_many :choices, -> { order(:position) }, class_name: 'CustomFieldChoice', dependent: :delete_all, inverse_of: :custom_field
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :required, inclusion: { in: [true, false] }
  validates :column_name, :name, presence: true, length: { maximum: 500 }
  validates :customized_type, :nature, presence: true
  validates :maximal_length, :minimal_length, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :maximal_value, :minimal_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  # ]VALIDATORS]
  validates :nature, length: { allow_nil: true, maximum: 20 }
  validates :nature, inclusion: { in: nature.values }
  validates :customized_type, inclusion: { in: customized_type.values }
  validates :column_name, uniqueness: { scope: [:customized_type] }
  validates :column_name, format: { with: /\A([a-z]+(\_[a-z]+)*)+\z/ }
  validates :column_name, exclusion: { in: ['_destroy'] }
  validates :customized_type, presence: true

  accepts_nested_attributes_for :choices
  acts_as_list scope: 'customized_type = \'#{customized_type}\''

  # default_scope -> { order(:customized_type, :position) }
  scope :actives, -> { where(active: true).order(:position) }
  scope :of, ->(model) { where(active: true, customized_type: model).order(:position) }

  before_validation do
    self.column_name ||= name
    if column_name
      self.column_name = self.column_name.parameterize.gsub(/[^a-z]+/, '_').gsub(/(^\_+|\_+$)/, '')[0..62]
      while others.where(column_name: column_name, customized_type: customized_type).any?
        column_name.succ!
      end
    end
  end

  validate do
    if customized_type.nil? || !customized_type.to_s.constantize.respond_to?(:custom_fields)
      errors.add(:customized_type, :invalid)
    end
  end

  delegate :count, to: :choices, prefix: true

  def sort_choices!
    choices.reorder(:name).to_a.each_with_index do |choice, index|
      choice.position = index + 1
      choice.save!
    end
  end

  def self.customizable_types
    Ekylibre::Schema.model_names.select do |model_name|
      model_name.to_s.constantize.respond_to?(:custom_fields)
    end
  end

  # Access to the customized model
  def customized_model
    customized_type.constantize
  end

  # Returns to the customized table name
  def customized_table_name
    customized_model.table_name
  end
end
