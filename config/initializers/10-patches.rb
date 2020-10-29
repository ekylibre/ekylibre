require 'tilt/coffee'

if defined? Encoding
  Encoding.default_internal = Encoding::UTF_8
  Encoding.default_external = Encoding::UTF_8
end

class ::String
  def tl(*args)
    ::I18n.translate('labels.' + self, *args)
  end
end

class ::Symbol
  def tl(*args)
    ::I18n.translate('labels.' + to_s, *args)
  end

  def ta(*args)
    ::I18n.translate('rest.actions.' + to_s, *args)
  end

  def tn(*args)
    ::I18n.translate('notifications.messages.' + to_s, *args)
  end

  def th(*args)
    args.each_with_index do |arg, _index|
      next unless arg.is_a?(Hash)
      for k, v in arg
        unless %i[locale scope default].include?(k)
          arg[k] = (v.html_safe? ? v : ('<em>' + CGI.escapeHTML(v) + '</em>').html_safe)
        end
      end
    end
    tl(*args).html_safe
  end
end

class ::DateTime
  def self.soft_parse(*args, &block)
    DateTime.parse(*args, &block)
  rescue ArgumentError
    nil
  end
end

class ::Date
  def self.soft_parse(*args, &block)
    Date.parse(*args, &block)
  rescue ArgumentError
    nil
  end
end

class ::Time
  def to_usec
    (utc.to_f * 1000).to_i
  end

  def round_off(interval = 60)
    Time.at((to_f / interval).round * interval).utc
  end
end

class ::Numeric
  # Computes decimal count. Examples:
  #  * 200 => -2
  #  * 1.350 => 2
  #  * 1.1 => 1
  def decimal_count
    return 0 if zero?
    count = 0
    value = dup
    integers_count = Math.log10(value.floor).ceil
    value /= 10 ** integers_count
    while value != value.to_i
      count += 1
      value *= 10
    end
    count - integers_count
  end

  # FROM ActiveSupport 6.0
  def minutes
    ActiveSupport::Duration.minutes(self)
  end
  alias minute minutes

  # FROM ActiveSupport 6.0
  def hours
    ActiveSupport::Duration.hours(self)
  end
  alias hour hours

  def semester
    (self * 6).months
  end

  def trimester
    (self * 3).months
  end

  alias trimesters trimester
  alias semesters semester

  def rounded_localize(precision: 2)
    round(precision).localize(precision: precision)
  end

  alias round_l rounded_localize
end

class ::BigDecimal
  # Overwrite badly bigdecimal
  # TODO: What to do for that ?
  def to_f
    to_s('F').to_f
  end
end

class ::Array
  def jsonize_keys
    map do |v|
      (v.respond_to?(:jsonize_keys) ? v.jsonize_keys : v)
    end
  end
end

class ::Hash
  def jsonize_keys
    deep_transform_keys do |key|
      key.to_s.camelize(:lower)
    end
  end

  def deep_compact
    each_with_object({}) do |pair, hash|
      k = pair.first
      v = pair.second
      v2 = (v.is_a?(Hash) ? v.deep_compact : v)
      hash[k] = v2 unless v2.nil? || (v2.is_a?(Hash) && v2.empty?)
      hash
    end
  end

  # Build a struct from the hash
  def to_struct
    OpenStruct.new(self)
  end

  def reverse
    self.flat_map { |key, values| values.map { |v| [v, key] } }
        .group_by(&:first)
        .map do |key, values|
          raise StandardError.new "Duplicate value for key #{key}: #{values.join(', ')}" if values.size > 1
          [key, values.first.second]
        end
        .to_h
  end
end

module Ekylibre
  module I18n
    module ContextualModelHelpers
      def tc(*args)
        args[0] = 'models.' + model_name.singular + '.' + args[0].to_s
        ::I18n.translate(*args)
      end
    end

    module ContextualModelInstanceHelpers
      def tc(*args)
        args[0] = 'models.' + self.class.model_name.singular + '.' + args[0].to_s
        ::I18n.translate(*args)
      end
    end

    module ContextualHelpers
      def tl(*args)
        args[0] = 'labels.' + args[0].to_s
        ::I18n.translate(*args)
      end
    end
  end
end

ActionController::Base.send :extend, Ekylibre::I18n::ContextualHelpers
ActionController::Base.send :include, Ekylibre::I18n::ContextualHelpers
ActiveRecord::Base.send :extend, Ekylibre::I18n::ContextualModelHelpers
ActiveRecord::Base.send :include, Ekylibre::I18n::ContextualModelInstanceHelpers
ActionView::Base.send :include, Ekylibre::I18n::ContextualHelpers

require 'state_machine/version'

unless StateMachine::VERSION == '1.2.0'
  # If you see this message, please test removing this file
  # If it's still required, please bump up the version above
  Rails.logger.warn 'Please remove me, StateMachine version has changed'
end

module StateMachine::Integrations::ActiveModel
  alias around_validation_protected around_validation

  def around_validation(*args, &block)
    around_validation_protected(*args, &block)
  end
end

module ActiveModel
  module Validations
    module SymbolHandlingClusitivity
      private

        # Redefining the #include? method to make sure we only pass strings
        # to be validated instead of "sometime strings, sometime symbols"
        def include?(record, value)
          value = value.to_s if value.is_a? Symbol
          super record, value
          # `super` here references ActiveModel::Validations::Clusitivity#include?
        end
    end

    # Including new module in the validators that use Clusivity
    InclusionValidator.include SymbolHandlingClusitivity
    ExclusionValidator.include SymbolHandlingClusitivity
  end
end

module ::I18n
  def self.locale_label(locale = nil)
    locale ||= self.locale
    "#{locale} (" + locale_name + ')'
  end

  def self.locale_name(locale = nil)
    locale ||= self.locale
    ::I18n.t('i18n.name')
  end

  # Returns translation if found else nil
  def self.translate_or_nil(*args)
    result = translate(*args)
    (result.to_s =~ /(translation\ missing|\(\(\()/ ? nil : result)
  end
end

# TODO: Get rid of this once the switch to Rails 5 has been made
module ActiveSupport
  class Duration
    ISO_INDEX_UNIT = { '1' => :year, '2' => :month, '3' => :day, '4' => :hour, '5' => :minute, '6' => :second }

    # FROM ActiveSupport 6.0
    SECONDS_PER_MINUTE = 60
    SECONDS_PER_HOUR = 3600
    SECONDS_PER_DAY = 86400
    SECONDS_PER_WEEK = 604800
    SECONDS_PER_MONTH = 2629746 # 1/12 of a gregorian year
    SECONDS_PER_YEAR = 31556952 # length of a gregorian year (365.2425 days)

    PARTS_IN_SECONDS = {
      seconds: 1,
      minutes: SECONDS_PER_MINUTE,
      hours: SECONDS_PER_HOUR,
      days: SECONDS_PER_DAY,
      weeks: SECONDS_PER_WEEK,
      months: SECONDS_PER_MONTH,
      years: SECONDS_PER_YEAR
    }.freeze
    # /FROM
    class << self
      # FROM ActiveSupport 6.0
      def seconds(value) #:nodoc:
        new(value, seconds: value)
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def minutes(value) #:nodoc:
        new(value * SECONDS_PER_MINUTE, minutes: value)
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def hours(value) #:nodoc:
        new(value * SECONDS_PER_HOUR, hours: value)
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def days(value) #:nodoc:
        new(value * SECONDS_PER_DAY, days: value)
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def weeks(value) #:nodoc:
        new(value * SECONDS_PER_WEEK, weeks: value)
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def months(value) #:nodoc:
        new(value * SECONDS_PER_MONTH, months: value)
      end unless ActiveSupport::Duration.methods.include?(:parse)

      # FROM ActiveSupport 6.0
      def years(value) #:nodoc:
        new(value * SECONDS_PER_YEAR, years: value)
      end unless ActiveSupport::Duration.methods.include?(:parse)

      def parse(string)
        hourly_format_match = string.match(/\A(\d{2}):(\d{2}):(\d{2})\z/)
        daily_format_match = string.match(/\A(\d+) days\z/)
        iso_format_match = string.match(/\AP(?:(\d*)Y)?(?:(\d*)M)?(?:(\d*)D)?(?:T(?:(\d*)H)?(?:(\d*)M)?(?:(\d*)S)?)?/)

        if hourly_format_match
          hourly_format_match[1].to_i.hour + hourly_format_match[2].to_i.minute + hourly_format_match[3].to_i.second
        elsif daily_format_match
          daily_format_match[1].to_i.day
        elsif iso_format_match
          (1..6).map { |int| iso_format_match[int] ? iso_format_match[int].to_i.send(ISO_INDEX_UNIT[int.to_s]) : nil }.compact.reduce(:+)
        end
      end unless ActiveSupport::Duration.methods.include?(:parse)
    end

    # FROM ActiveSupport 6.0
    def iso8601(precision: nil)
      ISO8601Serializer.new(self, precision: precision).serialize
    end unless ActiveSupport::Duration.instance_methods.include?(:iso8601)

    def in_full(unit)
      to_i / PARTS_IN_SECONDS[unit.to_s.pluralize.to_sym]
    end

    # FROM ActiveSupport 6.0
    class ISO8601Serializer # :nodoc:
      DATE_COMPONENTS = %i(years months days)

      def initialize(duration, precision: nil)
        @duration = duration
        @precision = precision
      end

      # Builds and returns output string.
      def serialize
        parts, sign = normalize
        return "PT0S" if parts.empty?

        output = +"P"
        output << "#{parts[:years]}Y" if parts.key?(:years)
        output << "#{parts[:months]}M" if parts.key?(:months)
        output << "#{parts[:days]}D" if parts.key?(:days)
        output << "#{parts[:weeks]}W" if parts.key?(:weeks)
        time = +""
        time << "#{parts[:hours]}H" if parts.key?(:hours)
        time << "#{parts[:minutes]}M" if parts.key?(:minutes)
        if parts.key?(:seconds)
          time << "#{sprintf(@precision ? "%0.0#{@precision}f" : '%g', parts[:seconds])}S"
        end
        output << "T#{time}" unless time.empty?
        "#{sign}#{output}"
      end

      private

      # Return pair of duration's parts and whole duration sign.
      # Parts are summarized (as they can become repetitive due to addition, etc).
      # Zero parts are removed as not significant.
      # If all parts are negative it will negate all of them and return minus as a sign.
      def normalize
        parts = @duration.parts.each_with_object(Hash.new(0)) do |(k, v), p|
          p[k] += v unless v.zero?
        end

        # Convert weeks to days and remove weeks if mixed with date parts
        if week_mixed_with_date?(parts)
          parts[:days] += parts.delete(:weeks) * SECONDS_PER_WEEK / SECONDS_PER_DAY
        end

        # If all parts are negative - let's make a negative duration
        sign = ""
        if parts.values.all? { |v| v < 0 }
          sign = "-"
          parts.transform_values!(&:-@)
        end
        [parts, sign]
      end

      def week_mixed_with_date?(parts)
        parts.key?(:weeks) && (parts.keys & DATE_COMPONENTS).any?
      end
    end unless constants.include?(:ISO8601Serializer)
  end
end
