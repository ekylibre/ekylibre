# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: intervention_casts
#
#  actor_id               :integer
#  created_at             :datetime         not null
#  creator_id             :integer
#  event_participation_id :integer
#  id                     :integer          not null, primary key
#  intervention_id        :integer          not null
#  lock_version           :integer          default(0), not null
#  nature                 :string(255)      not null
#  population             :decimal(19, 4)
#  position               :integer          not null
#  reference_name         :string(255)      not null
#  roles                  :string(320)
#  shape                  :spatial({:srid=>
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer
#

class InterventionCast < Ekylibre::Record::Base
  enumerize :nature, in: [:product, :variant], default: :product, predicates: {prefix: true}
  belongs_to :actor, class_name: "Product", inverse_of: :intervention_casts
  belongs_to :event_participation, dependent: :destroy
  belongs_to :intervention, inverse_of: :casts
  belongs_to :variant, class_name: "ProductNatureVariant"
  has_many :crumbs, dependent: :destroy
  has_one :product_nature, through: :variant, source: :nature
  has_one :activity, through: :intervention
  has_one :campaign, through: :intervention
  has_one :event,    through: :intervention
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_length_of :nature, :reference_name, allow_nil: true, maximum: 255
  validates_length_of :roles, allow_nil: true, maximum: 320
  validates_presence_of :intervention, :nature, :reference_name
  #]VALIDATORS]

  delegate :name, to: :actor, prefix: true
  delegate :name, to: :product_nature, prefix: true
  delegate :evaluated_price, to: :actor
  delegate :tracking, to: :actor
  delegate :started_at, :stopped_at, to: :intervention
  delegate :matching_model, to: :variant

  scope :of_role, lambda { |role|
    unless role.to_s =~ /\-/
      raise ArgumentError, "Need a valid role: <procedure_nature>-<role>"
    end
    nature, role = role.to_s.split('-')[0..1]
    where("roles ~ E?", "\\\\m(#{Nomen::ProcedureNatures.all(nature).sort.join('|')})-#{role}\\\\M")
  }

  scope :of_generic_role, lambda { |role|
    where("roles ~ E?", (role =~ /\-/  ? "\\\\m#{role}\\\\M" : "-#{role}\\\\M"))
  }

  scope :of_actor, lambda { |actor| where(actor_id: actor.id) }

  before_validation do
    if self.reference
      self.roles = self.reference.roles.join(', ')
      self.position = self.reference.position
    end
    if self.actor.is_a?(Product)
      self.variant  ||= self.actor.variant
      for indicator_name in self.actor.whole_indicators_list
        if self.send(indicator_name).blank? # and !reference.worked?
          self.send("#{indicator_name}=", self.actor.send(indicator_name, self.started_at))
        end
      end
    end
  end

  validate do
    errors.add(:reference_name, :invalid) unless self.reference
  end

  before_save do
    if self.nature_variant?
      self.actor = nil
    end

    if self.actor and self.actor.respond_to?(:person) and self.actor.person
      columns = {event_id: self.event.id, participant_id: self.actor.person_id, state: :accepted}
      if self.event_participation
        # self.event_participation.update_columns(columns)
        self.event_participation.attributes = columns
      else
        event_participation = EventParticipation.create!(columns)
        # self.update_column(:event_participation_id, event_participation.id)
        self.event_participation_id = event_participation.id
      end
    elsif self.event_participation
      self.event_participation.destroy!
    end
  end

  # multiply evaluated_price of an actor(product) and used population in this cast
  def cost
    if self.actor and price = self.evaluated_price
      if self.input?
        return price * (self.population || 0.0)
      elsif self.tool? or self.doer?
        return price * ((self.stopped_at - self.started_at).to_d / 3600)
      end
    end
    return nil
  end

  def earn
    if self.actor and price = self.evaluated_price
      if self.output?
        return price * (self.population || 0.0)
      end
    end
    return nil
  end

  def reference
    self.intervention.reference.variables[self.reference_name]
  end

  def variable_name
    self.reference.human_name
  end

  def name
    self.reference.human_name
  end


  def shape=(value)
    if value.is_a?(String) and value =~ /\A\{.*\}\z/
      value = Charta::Geometry.new(JSON.parse(value).to_json, :WGS84).to_rgeo
    elsif !value.blank?
      value = Charta::Geometry.new(value).to_rgeo
    end
    self["shape"] = value
  end

  # def shape
  #   Charta::Geometry.new(self["shape"])
  # end

  def shape_svg(options = {})
    geom = Charta::Geometry.new(self["shape"])
    geom = geom.transform(options[:srid]) if options[:srid]
    return geom.to_svg
  end

  for role in [:input, :output, :target, :tool, :doer]
    code  = "def #{role}?(procedure_nature = nil)\n"
    code << "  if procedure_nature\n"
    code << "    self.roles_array.detect{|r| r.first == procedure_nature and r.second == :#{role}}\n"
    code << "  else\n"
    code << "    self.roles_array.detect{|r| r.second == :#{role}}\n"
    code << "  end\n"
    code << "end\n"
    class_eval(code)
  end

  def roles_array
    self.roles.to_s.split(/[\,[[:space:]]]+/).collect{|role| role.split(/\-/)[0..1].map(&:to_sym) }
  end

  def human_roles
    self.roles_array.collect do |role|
      :x_of_y.tl(x: Nomen::ProcedureRoles[role.second].human_name, y: Nomen::ProcedureNatures[role.first].human_name.mb_chars.downcase)
    end.to_sentence
  end


  # Change name with default name like described in procedure
  # if default-name attribute is given too.
  # It uses interpolation to compose the wanted name. Not very i18nized
  # for now, but permits to do the job.
  def set_default_name!
    if self.reference.default_name? and produced = self.actor
      produced.update_column(:name, self.default_name)
    end
  end

  # Compute a default with given environment
  def default_name
    text = nil
    if self.reference.default_name?
      words = {
        campaign: self.campaign.name,
        activity: self.activity.name
      }.with_indifferent_access
      if produced = self.actor
        words[:variant]     = produced.variant_name
        words[:variety]     = Nomen::Varieties[produced.variety].human_name
        words[:derivative_of] = (produced.derivative_of ? Nomen::Varieties[produced.variety].human_name : nil)
        words[:container]   = (produced.container ? produced.container.name : nil)
        words[:default_storage] = (produced.default_storage ? produced.default_storage.name : nil)
        words[:born_at]     = produced.born_at.l
        words[:born_on]     = produced.born_at.to_date.l
        words[:birth_year]  = produced.born_at.year.to_s.rjust(4, '0')
        words[:birth_month] = produced.born_at.month.to_s.rjust(2, '0')
        words[:birth_day]   = produced.born_at.day.to_s.rjust(2, '0')
        words[:birth_month_name] = "date.month_names".t[produced.born_at.month]
        words[:birth_day_name]   = "date.day_names"[produced.born_at.wday]
        words[:birth_month_abbr] = "date.abbr_month_names".t[produced.born_at.month]
        words[:birth_day_abbr]   = "date.abbr_day_names"[produced.born_at.wday]
      end
      text = self.reference.default_name.dup.gsub(/\{\{\w+\}\}/) do |key|
        words[key[2..-3]]
      end
    end
    return text
  end


  # Define if the cast is valid for run
  def runnable?
    if self.reference.parted?
      if self.reference.known_variant?
        return self.population.present?
      else
        return (self.variant and self.population.present?)
      end
    elsif self.reference.produced?
      return self.variant
    elsif self.reference.type_variant?
      return self.variant
    else
      return self.actor
    end
    return false
  end


  # FIXME: Seems that Rails does not define population method when aggregators are used...
  def population
    self["population"]
  end

  # FIXME: Seems that Rails does not define population method when aggregators are used...
  def shape
    self["shape"]
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicators.all.include?(method_name.to_s) and self.actor and self.actor.respond_to?(:get)
      return self.actor.get(method_name, self)
    end
    return super
  end

end
