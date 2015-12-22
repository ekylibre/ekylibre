# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: intervention_parameters
#
#  created_at             :datetime         not null
#  creator_id             :integer
#  event_participation_id :integer
#  group_id               :integer
#  id                     :integer          not null, primary key
#  intervention_id        :integer          not null
#  lock_version           :integer          default(0), not null
#  new_container_id       :integer
#  new_group_id           :integer
#  new_variant_id         :integer
#  position               :integer          not null
#  product_id             :integer
#  quantity_handler       :string
#  quantity_indicator     :string
#  quantity_population    :decimal(19, 4)
#  quantity_unit          :string
#  quantity_value         :decimal(19, 4)
#  reference_name         :string           not null
#  source_product_id      :integer
#  type                   :string
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer
#  working_zone           :geometry({:srid=>4326, :type=>"multi_polygon"})
#

class InterventionProductParameter < InterventionParameter
  belongs_to :intervention, inverse_of: :product_parameters
  belongs_to :product, inverse_of: :intervention_product_parameters
  belongs_to :new_container, class_name: 'Product'
  belongs_to :new_group, class_name: 'ProductGroup'
  belongs_to :new_variant, class_name: 'ProductNatureVariant'
  belongs_to :variant, class_name: 'ProductNatureVariant'
  has_many :crumbs, dependent: :destroy, foreign_key: :intervention_parameter_id
  has_many :readings, class_name: 'InterventionParameterReading', dependent: :destroy, inverse_of: :intervention_cast
  has_one :product_nature, through: :variant, source: :nature
  has_one :activity, through: :intervention
  has_one :campaign, through: :intervention
  has_one :event,    through: :intervention

  has_geometry :working_zone, type: :multi_polygon
  composed_of :quantity, class_name: 'Measure', mapping: [%w(quantity_value to_d), %w(quantity_unit unit)]

  validates_presence_of :quantity_indicator, :quantity_unit, if: :quantity_handler?

  delegate :name, to: :product, prefix: true
  delegate :name, to: :product_nature, prefix: true
  delegate :evaluated_price, to: :product
  delegate :tracking, to: :product
  delegate :started_at, :stopped_at, :duration, :procedure, to: :intervention
  delegate :matching_model, to: :variant

  accepts_nested_attributes_for :readings, allow_destroy: true

  # scope :of_role, lambda { |role|
  #   fail 'No more usable'
  #   unless role.to_s =~ /\-/
  #     fail ArgumentError, 'Need a valid role: <procedure_nature>-<role>'
  #   end
  #   nature, role = role.to_s.split('-')[0..1]
  #   where('roles ~ E?', "\\\\m(#{Nomen::ProcedureNature.all(nature).sort.join('|')})-#{role}\\\\M")
  # }

  scope :of_generic_role, lambda { |role|
    role = role.to_s
    unless %w(doer input output target tool).include?(role)
      fail ArgumentError, "Invalid role: #{role}"
    end
    where(type: "Intervention#{role.camelize}")
  }
  scope :of_actor, ->(actor) { where(product_id: actor.id) }
  scope :of_actors, ->(actors) { where(product_id: actors.flatten.map(&:id)) }
  scope :with_actor, -> { where.not(product_id: nil) }

  before_validation do
    self.intervention = group.intervention if group && !intervention
    if reference
      if reference.handled? && quantity_handler?
        handler = reference[quantity_handler]
        if handler
          self.quantity_indicator = handler.indicator.name
          self.quantity_unit = handler.unit.name
        end
      end
    end
    if product.is_a?(Product)
      self.variant ||= product.variant
      # for indicator_name in product.whole_indicators_list
      #   if send(indicator_name).blank? # and !reference.worked?
      #     send("#{indicator_name}=", product.send(indicator_name, started_at))
      #   end
      # end
    end
  end

  validate do
    if intervention && intervention.procedure
      if reference
        if reference.handled? && quantity_handler?
          errors.add(:quantity_handler, :invalid) unless reference[quantity_handler]
        end
      else
        errors.add(:reference_name, :invalid)
      end
    end
  end

  # multiply evaluated_price of an product(product) and used quantity in this cast
  def cost
    if product && price = evaluated_price
      if self.input?
        return price * (quantity_value || 0.0)
      elsif self.tool? || self.doer?
        return price * (duration.to_d / 3600)
      end
    end
    nil
  end
  
  # show how evaluated_price of an product(product) is build
  def cost_label
    # case of intrant / tool / doer
    if product && price_label = evaluated_price
       if self.input?
        return "#{quantity.l} x #{price_label.l(currency: Preference[:currency])}"
      elsif self.tool? || self.doer?
        return "#{(duration.to_d / 3600).in(:hour).l} x #{price_label.l(currency: Preference[:currency])}"
      end
    # case of extrant  
    elsif variant
      return "Not implemented"
       # try to get the last purchase price of the same variant if any.
      
       # try to get the last sale price of the same variant if any.
       
    # case of transformation or evolution, changing variant
    elsif new_variant
       return "Not implemented"
    end
  end

  def earn
    if product && price = evaluated_price
      return price * (quantity_value || 0.0) if self.output?
    end
    nil
  end

  def name
    reference ? reference.human_name : reference_name.humanize
  end

  def shape_svg(options = {})
    geom = Charta.new_geometry(self['shape'])
    geom = geom.transform(options[:srid]) if options[:srid]
    geom.to_svg
  end

  def self.role
    @name ||= name.gsub(/^Intervention/, '').underscore.to_sym
  end

  def role
    self.class.role
  end

  [:doer, :input, :output, :target, :tool].each do |role|
    code = "def #{role}?\n"
    code << "  self.type.to_s == 'Intervention#{role.to_s.camelize}'\n"
    code << "end\n"
    class_eval(code)
  end

  # def roles_array
  #   roles.to_s.split(/[\,[[:space:]]]+/).collect { |role| role.split(/\-/)[0..1].map(&:to_sym) }
  # end

  # def human_roles
  #   roles_array.collect do |role|
  #     :x_of_y.tl(x: Nomen::ProcedureRole[role.second].human_name, y: Nomen::ProcedureNature[role.first].human_name.mb_chars.downcase)
  #   end.to_sentence
  # end

  # Change name with default name like described in procedure
  # if default-name attribute is given too.
  # It uses interpolation to compose the wanted name. Not very i18nized
  # for now, but permits to do the job.
  def set_default_name!
    if reference.default_name? && produced = product
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
      if produced = product
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
        words[:birth_day_name]   = 'date.day_names'.t[produced.born_at.wday]
        words[:birth_month_abbr] = 'date.abbr_month_names'.t[produced.born_at.month]
        words[:birth_day_abbr]   = 'date.abbr_day_names'.t[produced.born_at.wday]
      end
      text = reference.default_name.dup.gsub(/\{\{\w+\}\}/) do |key|
        words[key[2..-3]]
      end
    end
    text
  end

  # Define if the cast is valid for run
  def runnable?
    return true
    if reference.parted?
      if reference.known_variant?
        return quantity.present?
      else
        return (self.variant && quantity.present?)
      end
    elsif reference.produced?
      return self.variant
    elsif reference.type_variant?
      return self.variant
    else
      return product
    end
    false
  end

  # FIXME: Seems that Rails does not define population method when aggregators are used...
  def population
    self['quantity']
  end

  # FIXME: Seems that Rails does not define shape method when aggregators are used...
  def shape
    self['shape']
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicator.all.include?(method_name.to_s) && product && product.respond_to?(:get)
      return product.get(method_name, self)
    end
    super
  end
end
