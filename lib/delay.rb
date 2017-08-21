# -*- coding: utf-8 -*-
class InvalidDelayExpression < ArgumentError
end

# Delay permits to define explicit and complex delays
# Delay are not always linears due to BOM/EOM, so if D3 = D1 + D2 is true, D1 = D2 - D3 is not always true.
class Delay
  SEPARATOR = ','.freeze
  TRANSLATIONS = {
    'an' => :year,
    'ans' => :year,
    'année' => :year,
    'années' => :year,
    'annee' => :year,
    'annees' => :year,
    'year' => :year,
    'years' => :year,
    'mois' => :month,
    'month' => :month,
    'months' => :month,
    'week' => :week,
    'semaine' => :week,
    'weeks' => :week,
    'semaines' => :week,
    'jour' => :day,
    'day' => :day,
    'jours' => :day,
    'days' => :day,
    'heure' => :hour,
    'hour' => :hour,
    'heures' => :hour,
    'hours' => :hour,
    'minute' => :minute,
    'minutes' => :minute,
    'seconde' => :second,
    'second' => :second,
    'secondes' => :second,
    'seconds' => :second
  }.freeze
  KEYS = TRANSLATIONS.keys.join('|').freeze

  attr_reader :expression

  def initialize(expression = nil)
    base = (expression.nil? ? nil : expression.dup)
    expression ||= []
    expression = expression.to_s.strip.split(/\s*\,\s*/) if expression.is_a?(String)
    unless expression.is_a?(Array)
      raise ArgumentError, "String or Array expected (got #{expression.class.name}:#{expression.inspect})"
    end
    @expression = expression.collect do |step|
      # step = step.mb_chars.downcase
      if step =~ /\A(eom|end of month|fdm|fin de mois)\z/
        [:eom]
      elsif step =~ /\A(bom|beginning of month|ddm|debut de mois|début de mois)\z/
        [:bom]
      elsif step =~ /\A\d+\ (#{KEYS})(\ (avant|ago))?\z/
        words = step.split(/\s+/).map(&:to_s)
        if TRANSLATIONS[words[1]].nil?
          raise InvalidDelayExpression, "#{words[1].inspect} is an undefined period (#{step.inspect} of #{base.inspect})"
        end
        [TRANSLATIONS[words[1]], (words[2].blank? ? 1 : -1) * words[0].to_i]
      elsif step.present?
        raise InvalidDelayExpression, "#{step.inspect} is an invalid step. (From #{base.inspect} => #{expression.inspect})"
      end
    end
  end

  def compute(started_at = Time.zone.now)
    return nil if started_at.nil?
    stopped_at = started_at.dup
    @expression.each do |step|
      case step[0]
      when :eom
        stopped_at = stopped_at.end_of_month
      when :bom
        stopped_at = stopped_at.beginning_of_month
      else
        stopped_at += step[1].send(step[0])
      end
    end
    stopped_at
  end

  def inspect
    @expression.collect do |step|
      next step.first.to_s.upcase if step.size == 1
      step[1].abs.to_s + ' ' + step[0].to_s + 's' + (step[1] < 0 ? ' ago' : '')
    end.join(', ')
  end

  def to_s
    inspect
  end

  # Invert steps :
  #   * EOM -> BOM
  #   * BOM -> EOM
  #   * x <duration> -> x <duration> ago
  def invert!
    @expression = @expression.collect do |step|
      if step.first == :eom
        [:bom]
      elsif step.first == :bom
        [:eom]
      else
        [step.first, -step.second]
      end
    end
    self
  end

  # Return a duplicated inverted copy
  def invert
    dup.invert!
  end

  # Sums delays
  def +(delay)
    if delay.is_a?(Delay)
      Delay.new(to_s + ', ' + delay.to_s)
    elsif delay.is_a?(String)
      Delay.new(to_s + ', ' + Delay.new(delay).to_s)
    elsif delay.is_a?(Numeric)
      Delay.new(to_s + ', ' + Delay.new(delay.to_s + ' seconds').to_s)
    elsif delay.is_a?(Measure) && delay.dimension == :time && %i[second minute hour day month year].include?(delay.unit.to_sym)
      Delay.new(to_s + ', ' + Delay.new(delay.value.to_i.to_s + ' ' + delay.unit.to_s).to_s)
    else
      raise ArgumentError, "Cannot sum #{delay} [#{delay.class.name}] to a #{self.class.name}"
    end
  end

  # Adds opposites values of given delay
  def -(delay)
    if delay.is_a?(Delay)
      Delay.new(to_s + ', ' + delay.invert.to_s)
    elsif delay.is_a?(String)
      Delay.new(to_s + ', ' + Delay.new(delay).invert.to_s)
    elsif delay.is_a?(Numeric)
      Delay.new(to_s + ', ' + Delay.new(delay.to_s + ' seconds').invert.to_s)
    elsif delay.is_a?(Measure) && delay.dimension == :time && %i[second minute hour day month year].include?(delay.unit.to_sym)
      Delay.new(to_s + ', ' + Delay.new(delay.value.to_i.to_s + ' ' + delay.unit.to_s).invert.to_s)
    else
      raise ArgumentError, "Cannot subtract #{delay} [#{delay.class.name}] from a #{self.class.name}"
    end
  end

  module Validation
    module Validator
    end

    module ClassMethods
      def validates_delay_format_of(*attr_names)
        attr_names.each do |attr_name|
          validates attr_name, delay: true
        end
        # validates_with ActiveRecord::Base::DelayFormatValidator, *attr_names
      end
    end
  end
end

class DelayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    Delay.new(value)
  rescue InvalidDelayExpression => e
    record.errors.add(attribute, :invalid, options.merge(value: value))
  end
end
