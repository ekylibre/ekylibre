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
  has_many :product_deaths, dependent: :destroy
  has_many :product_links, dependent: :destroy
  has_many :product_localizations, dependent: :destroy
  has_many :product_measurements, dependent: :destroy
  enumerize :nature, in: Procedo::Action::TYPES.keys, predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :reference_name, allow_nil: true, maximum: 255
  validates_inclusion_of :prorated, in: [true, false]
  validates_presence_of :nature, :operation, :reference_name
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values

  delegate :reference, to: :operation, prefix: true
  delegate :intervention, :started_at, :stopped_at, :casts, to: :operation
  delegate :name, to: :intervention, prefix: true

  before_validation do
    self.nature = self.reference.action.type
  end

  after_create do
    # Load casting ?

    # Repeat tasks for every member, how ? by reading task
    if self.prorated
    end

    # Let the magic begins
    method_name = "do_#{self.nature}".to_sym
    if self.respond_to?(method_name)
      begin
        send(method_name)
      rescue Exception => e
        puts "\n" * 3
        puts "*" * 80 + "\n"
        puts "* Procedure: #{self.operation.intervention.reference_name}/#{self.operation.reference_name}/#{self.reference_name}\n"
        puts "* #{self.nature.humanize}: #{find_actors.inspect[1..-2]}\n"
        puts "* OID: #{self.operation_id}\n"
        puts "*" * 80 + "\n"
        puts "Can not do #{self.nature}: " +
          e.message.to_s + "\nBacktrace:\n" +
          e.backtrace.select{|x| x.match(Rails.root.to_s)}[0..9].join("\n")
      end
    else
      puts "Unsupported method: #{method_name}"
    end
  end

  before_destroy do
    method_name = "undo_#{self.nature}".to_sym
    if self.respond_to?(method_name)
      begin
        send(method_name)
      rescue
        puts "Can not undo #{self.nature}"
      end
    end
  end


  def reference
    self.operation_reference.tasks[self.reference_name]
  end


  # == Localization

  def do_direct_movement
    self.product_localizations.create!(started_at: self.started_at, nature: :interior, product_id: find_actor(:product).id, container_id: find_actor(:localizable).container(self.started_at).id)
  end

  def do_direct_entering
    self.product_localizations.create!(started_at: self.started_at, nature: :interior, product_id: find_actor(:product).id, container_id: find_actor(:localizable).id)
  end

  def do_movement
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: product.id, container_id: find_actor(:localizable).container(self.stopped_at).id)
  end

  def do_entering
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: product.id, container_id: find_actor(:localizable).id)
  end

  def do_home_coming
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: product.id, container_id: product.default_storage.id)
  end

  def do_given_home_coming
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: product.id, container_id: find_actor(:localizable).default_storage.id)
  end

  def do_out_going
    product = find_actor(:product)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: product.id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :exterior, product_id: product.id)
  end

  # == Births

  def do_creation
    self.product_births.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :creation, product: find_actor(:product), producer: find_actor(:producer))
  end

  def do_division
    self.product_births.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :division, product: find_actor(:product), producer: find_actor(:producer))
  end

  # == Deaths

  def do_consumption
    self.product_deaths.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :consumption, product: find_actor(:product), absorber: find_actor(:absorber))
  end

  def do_merging
    self.product_deaths.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :merging, product: find_actor(:product), absorber: find_actor(:absorber))
  end

  # == Links

  def do_attachment
    self.product_links.create!(started_at: self.stopped_at, carrier: find_actor(:carrier), carried: find_actor(:carried))
  end

  def do_detachment
    self.product_links
      .where(carrier_id: find_actor(:carrier).id, carried_id: find_actor(:carried).id)
      .at(self.stopped_at)
      .find_each do |link|
      link.update_attribute(stopped_at: self.stopped_at)
    end
  end

  def undo_detachment
    self.product_links
      .where(carrier_id: find_actor(:carrier).id, carried_id: find_actor(:carried).id, stopped_at: self.stopped_at)
      .find_each do |link|
      link.update_attribute(stopped_at: nil)
    end
  end

  # == Memberships

  def do_group_inclusion
    self.product_memberships.create!(started_at: self.stopped_at, member: find_actor(:member), group: find_action(:group))
  end

  def do_group_exclusion
    self.product_memberships
      .where(member_id: find_actor(:member).id, group_id: find_actor(:group).id)
      .at(self.stopped_at)
      .find_each do |membership|
      membership.update_attribute(stopped_at: self.stopped_at)
    end
  end

  def undo_group_exclusion
    self.product_memberships
      .where(member_id: find_actor(:member).id, group_id: find_actor(:group).id, stopped_at: self.stopped_at)
      .find_each do |membership|
      membership.update_attribute(stopped_at: nil)
    end
  end

  # == Ownership

  def do_ownership_loss
    self.product_ownerships.create!(started_at: self.stopped_at, nature: :unknown, product_id: product.id)
  end

  def do_ownership_change
    self.product_ownerships.create!(started_at: self.stopped_at, product_id: product.id, owner: find_actor(:owner))
  end

  # == Browsing

  def do_browsing
  end

  # == Measurement

  def do_measurement
  end

  def do_simple_measurement
    # product, indicator = find_actor(:indicator)
    # self.product_measurements.create!(product: product, indicator: indicator)
  end


  private

  # Find the actor from operation casting through action types
  def find_actor(name)
    parameter = reference.parameters[name.to_sym]
    if parameter.is_a?(Procedo::Variable)
      cast = self.casts.find_by!(reference_name: parameter.name.to_s)
      return cast.actor
    elsif parameter.is_a?(Procedo::Indicator)
      cast = self.casts.find_by!(reference_name: parameter.stakeholder.name.to_s)
      return [cast.actor, parameter.indicator]
    else
      raise StandardError, "Don't known how to find a #{cast.class.name}"
    end
  end


  def find_actors
    return reference.parameters.inject({}) do |hash, pair|
      hash[pair.first] = find_actor(pair.second.name) rescue "¿#{pair.second.name}?"
      hash
    end
  end

end
