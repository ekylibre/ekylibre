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

  def semester
    months * 6
  end

  def trimester
    months * 3
  end

  alias trimesters trimester
  alias semesters semester
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
