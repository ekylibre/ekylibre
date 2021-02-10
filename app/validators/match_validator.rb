class MatchValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    @record = record
    @attribute = attribute
    @value = value

    return if empty_comparisons?

    record.errors.add(attribute_to_invalidate, :invalid) unless equals?(reference, comparison)
  end

  def check_validity!
    raise ArgumentError.new(<<-ERROR) unless options[:with]
      Please specify who the record should match property #{attribute} on with option :with"
    ERROR
  end

  private

    def attribute_to_invalidate
      options[:to_invalidate] || @attribute
    end

    def reference
      return @value unless options[:middleman]

      middleman.send(@attribute)
    end

    def middleman
      middleman = options[:middleman]
      return unless middleman

      @record.send(middleman)
    end

    def with
      @record.send(options[:with])
    end

    def comparison
      with.send(@attribute)
    end

    def empty_comparisons?
      return with.blank? unless options[:middleman]

      with.blank? && middleman.blank?
    end

    def equals?(val, oth)
      val = val.to_s if val.is_a? Symbol
      oth = oth.to_s if oth.is_a? Symbol
      val == oth
    end
end
