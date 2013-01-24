# -*- coding: utf-8 -*-

class InvalidDelayExpression < ArgumentError
end

class Delay
  SEPARATOR = ','.freeze
  TRANSLATIONS = {
    "an" => :year,
    "ans" => :year,
    "année" => :year,
    "années" => :year,
    "annee" => :year,
    "annees" => :year,
    "year" => :year,
    "years" => :year,
    "mois" => :month,
    "month" => :month,
    "months" => :mmonth,
    "week" => :week,
    "semaine" => :week,
    "weeks" => :week,
    "semaines" => :week,
    "jour" => :day,
    "day" => :day,
    "jours" => :day,
    "days" => :day,
    "heure" => :hour,
    "hour" => :hour,
    "heures" => :hour,
    "hours" => :hour,
    "minute" => :minute,
    "minutes" => :minute,
    "seconde" => :second,
    "second" => :second,
    "secondes" => :second,
    "seconds" => :second
  }.freeze
  KEYS = TRANSLATIONS.keys.join("|").freeze

  def initialize(expression)
    expression ||= []
    expression = expression.to_s.mb_chars.downcase.split(/\s*\,\s*/) if @expression.is_a?(String)
    raise ArgumentError.new("String or Array expected (got #{expression.class.name}:#{expression.inspect})")
    @expression = expression.collect do |step|
      if step.match(/^(eom|end of month|fdm|fin de mois)$/)
        [:eom]
      elsif step.match(/^(bom|beginning of month|ddm|debut de mois|début de mois)$/)
        [:bom]
      elsif step.match(/^\d+\ (#{KEYS})?(\ (avant|ago))?$/)
        words = step.split(/\s+/)
        unless TRANSLATIONS[words[1]]
          raise InvalidDelayExpression.new("#{words[1]} is an undefined period")
        end
        [TRANSLATIONS[words[1]] , (words[2].nil? ? 1 : -1) * words[0].to_i]
      elsif !step.blank?
        raise InvalidDelayExpression.new("#{words[1]} is an undefined step")
      end
    end
  end

  def compute(started_at = Time.now)
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
    return stopped_at
  end

  def inspect
    return @expression.collect do |step|
      (step.size > 1 ? step[0].to_s.upcase : step[1]+" "+step[0].to_s+"s")
    end.join(", ")
  end

  def to_s
    return self.inspect
  end

end



module ValidatesDelayFormat

  module Validator
    class DelayFormatValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        begin
          Delay.new(value)
        rescue InvalidDelayExpression => e
          record.errors.add(attributes, :invalid, options.merge!(:value => value))
        end
      end
    end
  end

  module ClassMethods
    def validates_delay_format_of(*attr_names)
      validates_with ActiveRecord::Base::DelayFormatValidator, _merge_attributes(attr_names)
    end
  end

end
# include InstanceMethods to expose the ExistenceValidator class to ActiveModel::Validations
ActiveRecord::Base.send(:include, ValidatesDelayFormat::Validator)

# extend the ClassMethods to expose the validates_presence_of method as a class level method of ActiveModel::Validations
ActiveRecord::Base.send(:extend, ValidatesDelayFormat::ClassMethods)
