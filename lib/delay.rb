class InvalidDelayExpression < ArgumentError
end

# Delay permits to define explicit and complex delays
# Delay are not always linears due to BOM/EOM, so if D3 = D1 + D2 is true, D1 = D2 - D3 is not always true.
class Delay
  SEPARATOR = ','.freeze
  TRANSLATIONS = {
    fra: {
      'an' => :year,
      'ans' => :year,
      'année' => :year,
      'années' => :year,
      'annee' => :year,
      'annees' => :year,
      'mois' => :month,
      'semaine' => :week,
      'semaines' => :week,
      'jour' => :day,
      'jours' => :day,
      'heure' => :hour,
      'heures' => :hour,
      'minute' => :minute,
      'minutes' => :minute,
      'seconde' => :second,
      'secondes' => :second
    }.freeze,
    eng: {
      'year' => :year,
      'years' => :year,
      'month' => :month,
      'months' => :month,
      'week' => :week,
      'weeks' => :week,
      'day' => :day,
      'days' => :day,
      'hour' => :hour,
      'hours' => :hour,
      'minute' => :minute,
      'minutes' => :minute,
      'second' => :second,
      'seconds' => :second,
    }.freeze
  }.freeze

  KEYS = TRANSLATIONS.values.reduce(&:merge).keys.join('|').freeze
  ALL_TRANSLATIONS = TRANSLATIONS.values.reduce(&:merge).freeze
  MONTH_KEYWORDS = {
    bom: {
      eng: ['bom', 'beginning of month'].freeze,
      fra: ['ddm', 'début du mois'].freeze
    }.freeze,
    eom: {
      eng: ['eom', 'end of month'].freeze,
      fra: ['fdm', 'fin du mois'].freeze
    }.freeze
  }.freeze

  attr_reader :expression

  def initialize(expression = nil)
    base = (expression.nil? ? nil : expression.dup)
    expression ||= []
    expression = expression.to_s.strip.split(/\s*\,\s*/) if expression.is_a?(String)
    unless expression.is_a?(Array)
      raise ArgumentError.new("String or Array expected (got #{expression.class.name}:#{expression.inspect})")
    end

    @expression = expression.collect do |step|
      # step = step.mb_chars.downcase
      if step =~ /\A(#{MONTH_KEYWORDS[:eom].values.flatten.join('|')})\z/
        [:eom]
      elsif step =~ /\A(#{MONTH_KEYWORDS[:bom].values.flatten.join('|')})\z/
        [:bom]
      elsif step =~ /\A\d+\ (#{KEYS})(\ (avant|ago))?\z/
        words = step.split(/\s+/).map(&:to_s)
        if ALL_TRANSLATIONS[words[1]].nil?
          raise InvalidDelayExpression.new("#{words[1].inspect} is an undefined period (#{step.inspect} of #{base.inspect})")
        end

        [ALL_TRANSLATIONS[words[1]], (words[2].blank? ? 1 : -1) * words[0].to_i]
      elsif step.present?
        raise InvalidDelayExpression.new("#{step.inspect} is an invalid step. (From #{base.inspect} => #{expression.inspect})")
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
      raise ArgumentError.new("Cannot sum #{delay} [#{delay.class.name}] to a #{self.class.name}")
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
      raise ArgumentError.new("Cannot subtract #{delay} [#{delay.class.name}] from a #{self.class.name}")
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
  rescue InvalidDelayExpression
    record.errors.add(attribute, method(:bad_delay_message).to_proc, options.merge(value: value))
  end

  private

    def bad_delay_message(*_args)
      message_key = 'activerecord.errors.models.purchase.payment_delay_custom_validation_message'
      delay_arguments = delay_arguments_for(Preference[:language]) || delay_arguments_for(:eng)
      month_keywords = month_keywords_for(Preference[:language]) || month_keywords_for(:eng)
      values = delay_arguments + month_keywords
      I18n.translate(message_key, values: values.join(', '))
    end

    def delay_arguments_for(language)
      language = language.to_sym
      keywords = Delay::TRANSLATIONS[language]&.keys
    end

    def month_keywords_for(language)
      language = language.to_sym
      bom = Delay::MONTH_KEYWORDS[:bom][language]
      eom = Delay::MONTH_KEYWORDS[:eom][language]
      return nil unless bom ||  eom

      (bom || []) + (eom ||  [])
    end
end
