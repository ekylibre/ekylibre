# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: intervention_casts
#
#  actor_id               :integer
#  created_at             :datetime         not null
#  creator_id             :integer
#  event_participation_id :integer
#  id                     :integer          not null, primary key
#  intervention_id        :integer          not null
#  lock_version           :integer          default(0), not null
#  nature                 :string           not null
#  population             :decimal(19, 4)
#  position               :integer          not null
#  reference_name         :string           not null
#  roles                  :string
#  shape                  :geometry({:srid=>4326, :type=>"geometry"})
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer
#

class InterventionCast < Ekylibre::Record::Base
  enumerize :nature, in: [:product, :variant], default: :product, predicates: { prefix: true }
  belongs_to :actor, class_name: 'Product', inverse_of: :intervention_casts
  belongs_to :event_participation, dependent: :destroy
  belongs_to :intervention, inverse_of: :casts
  belongs_to :variant, class_name: 'ProductNatureVariant'
  has_many :crumbs, dependent: :destroy
  has_one :product_nature, through: :variant, source: :nature
  has_one :activity, through: :intervention
  has_one :campaign, through: :intervention
  has_one :event,    through: :intervention
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_presence_of :intervention, :nature, :reference_name
  # ]VALIDATORS]
  validates_length_of :roles, allow_nil: true, maximum: 320

  delegate :name, to: :actor, prefix: true
  delegate :name, to: :product_nature, prefix: true
  delegate :evaluated_price, to: :actor
  delegate :tracking, to: :actor
  delegate :started_at, :stopped_at, to: :intervention
  delegate :matching_model, to: :variant

  scope :of_role, lambda { |role|
    unless role.to_s =~ /\-/
      fail ArgumentError, 'Need a valid role: <procedure_nature>-<role>'
    end
    nature, role = role.to_s.split('-')[0..1]
    where('roles ~ E?', "\\\\m(#{Nomen::ProcedureNature.all(nature).sort.join('|')})-#{role}\\\\M")
  }

  scope :of_generic_role, lambda { |role|
    where('roles ~ E?', (role =~ /\-/ ? "\\\\m#{role}\\\\M" : "-#{role}\\\\M"))
  }

  scope :of_actor, ->(actor) { where(actor_id: actor.id) }
  scope :with_actor, -> { where.not(actor_id: nil) }

  before_validation do
    if reference
      self.roles = reference.roles.join(', ')
      self.position = reference.position
    else
      precision = 10**8
      now = Time.zone.now
      self.position ||= (precision * now.to_f).round - (precision * now.to_i)
    end
    if self.actor.is_a?(Product)
      self.variant ||= self.actor.variant
      for indicator_name in self.actor.whole_indicators_list
        if send(indicator_name).blank? # and !reference.worked?
          send("#{indicator_name}=", self.actor.send(indicator_name, started_at))
        end
      end
    end
  end

  validate do
    if intervention && intervention.reference
      errors.add(:reference_name, :invalid) unless reference
    end
  end

  before_save do
    self.actor = nil if nature_variant?

    if self.actor && self.actor.respond_to?(:person) && self.actor.person
      columns = { event_id: event.id, participant_id: self.actor.person_id, state: :accepted }
      if event_participation
        # self.event_participation.update_columns(columns)
        event_participation.attributes = columns
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
    if actor && price = evaluated_price
      if input?
        return price * (population || 0.0)
      elsif tool? || doer?
        return price * ((stopped_at - started_at).to_d / 3600)
      end
    end
    nil
  end

  def duration
    (stopped_at - started_at).in(:second)
  end

  def earn
    if actor && price = evaluated_price
      return price * (population || 0.0) if output?
    end
    nil
  end

  def reference
    if intervention && reference = intervention.reference
      @reference ||= reference.variables[reference_name]
    else
      @reference = nil
    end
  end

  def variable_name
    name
  end

  def name
    reference ? reference.human_name : reference_name.humanize
  end

  def shape=(value)
    if value.is_a?(String) && value =~ /\A\{.*\}\z/
      value = Charta::Geometry.new(JSON.parse(value).to_json, :WGS84).to_rgeo
    elsif !value.blank?
      value = Charta::Geometry.new(value).to_rgeo
    end
    self['shape'] = value
  end

  # def shape
  #   Charta::Geometry.new(self["shape"])
  # end

  def shape_svg(options = {})
    geom = Charta::Geometry.new(self['shape'])
    geom = geom.transform(options[:srid]) if options[:srid]
    geom.to_svg
  end

  for role in [:input, :output, :target, :tool, :doer]
    code = "def #{role}?(procedure_nature = nil)\n"
    code << "  if procedure_nature\n"
    code << "    self.roles_array.detect{|r| r.first == procedure_nature and r.second == :#{role}}\n"
    code << "  else\n"
    code << "    self.roles_array.detect{|r| r.second == :#{role}}\n"
    code << "  end\n"
    code << "end\n"
    class_eval(code)
  end

  def roles_array
    roles.to_s.split(/[\,[[:space:]]]+/).collect { |role| role.split(/\-/)[0..1].map(&:to_sym) }
  end

  def human_roles
    roles_array.collect do |role|
      :x_of_y.tl(x: Nomen::ProcedureRole[role.second].human_name, y: Nomen::ProcedureNature[role.first].human_name.mb_chars.downcase)
    end.to_sentence
  end

  # Change name with default name like described in procedure
  # if default-name attribute is given too.
  # It uses interpolation to compose the wanted name. Not very i18nized
  # for now, but permits to do the job.
  def set_default_name!
    if reference.default_name? && produced = actor
      produced.update_column(:name, default_name)
    end
  end

  # Compute a default with given environment
  def default_name
    text = nil
    if reference.default_name?
      words = {
        campaign: campaign.name,
        activity: activity.name
      }.with_indifferent_access
      if produced = actor
        words[:variant]     = produced.variant_name
        words[:variety]     = Nomen::Variety[produced.variety].human_name
        words[:derivative_of] = (produced.derivative_of ? Nomen::Variety[produced.variety].human_name : nil)
        words[:container] = (produced.container ? produced.container.name : nil)
        words[:default_storage] = (produced.default_storage ? produced.default_storage.name : nil)
        words[:born_at]     = produced.born_at.l
        words[:born_on]     = produced.born_at.to_date.l
        words[:birth_year]  = produced.born_at.year.to_s.rjust(4, '0')
        words[:birth_month] = produced.born_at.month.to_s.rjust(2, '0')
        words[:birth_day]   = produced.born_at.day.to_s.rjust(2, '0')
        words[:birth_month_name] = 'date.month_names'.t[produced.born_at.month]
        words[:birth_day_name]   = 'date.day_names'[produced.born_at.wday]
        words[:birth_month_abbr] = 'date.abbr_month_names'.t[produced.born_at.month]
        words[:birth_day_abbr]   = 'date.abbr_day_names'[produced.born_at.wday]
      end
      text = reference.default_name.dup.gsub(/\{\{\w+\}\}/) do |key|
        words[key[2..-3]]
      end
    end
    text
  end

  # Define if the cast is valid for run
  def runnable?
    if reference.parted?
      if reference.known_variant?
        return population.present?
      else
        return (self.variant && population.present?)
      end
    elsif reference.produced?
      return self.variant
    elsif reference.type_variant?
      return self.variant
    else
      return actor
    end
    false
  end

  # FIXME: Seems that Rails does not define population method when aggregators are used...
  def population
    self['population']
  end

  # FIXME: Seems that Rails does not define population method when aggregators are used...
  def shape
    self['shape']
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicator.all.include?(method_name.to_s) && actor && actor.respond_to?(:get)
      return actor.get(method_name, self)
    end
    super
  end
end
