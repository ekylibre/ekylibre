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
# == Table: operation_tasks
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  nature         :string(255)      not null
#  operation_id   :integer          not null
#  parent_id      :integer
#  prorated       :boolean          not null
#  reference_name :string(255)      not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#
class OperationTask < Ekylibre::Record::Base
  belongs_to :operation, inverse_of: :tasks
  belongs_to :parent, class_name: "OperationTask"
  has_many :casts, class_name: "OperationTaskCast", inverse_of: :task
  has_many :product_births, dependent: :destroy
  has_many :product_localizations, dependent: :destroy
  enumerize :nature, in: Procedo::Action::TYPES.keys, predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :reference_name, allow_nil: true, maximum: 255
  validates_inclusion_of :prorated, in: [true, false]
  validates_presence_of :nature, :operation, :reference_name
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values

  delegate :reference, to: :operation, prefix: true
  delegate :started_at, :stopped_at, :casts, to: :operation

  before_validation do
    self.nature = self.reference.action.type
  end

  after_create do
    # Load casting ?

    # Repeat tasks for every member, how ? by reading task
    if self.prorated
    end

    # Let the magic begins
    method_name = "add_#{self.nature}".to_sym
    if self.respond_to?(method_name)
      send(method_name)
    else
      puts "Unsupported method: #{method_name}"
    end
  end

  def reference
    self.operation_reference.tasks[self.reference_name]
  end

  def add_movement
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: product.id, container_id: find_actor(:localizable).container.id)
  end

  def add_entering
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: product.id, container_id: find_actor(:localizable).id)
  end

  def add_home_coming
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: product.id, container_id: product.default_storage.id)
  end

  def add_given_home_coming
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: product.id, container_id: find_actor(:localizable).default_storage.id)
  end

  def add_out_going
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :exterior, product_id: product.id)
  end

  def add_division
    self.product_births.create!(started_at: self.started_at, stopped_at: self.stopped_at, born: find_actor(:born), genitor: find_actor(:product))
  end

  private

  # Find the actor from operation casting through action types
  def find_actor(name)
    parameter = reference.parameters[name.to_sym]
    if parameter.is_a?(Procedo::Variable)
      cast = self.casts.find_by!(reference_name: parameter.name.to_s)
      return cast.actor
    else
      raise StandardError, "Don't known how to find a #{cast.class.name}"
    end
  end

end
