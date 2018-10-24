class MatchValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    @record = record
    @attribute = attribute
    @value = value

    record.errors.add(attribute_to_invalidate, :invalid) unless equals?(reference, comparison)
  end

  def check_validity!
    raise ArgumentError, <<-ERROR unless options[:with]
      Please specify who the record should match property #{attribute} on with option :with"
    ERROR
  end

  private

  def attribute_to_invalidate
    opions[:to_invalidate] || @attribute
  end

  def reference(record, attribute)
    return @value unless options[:middleman]
    record.send(middleman).send(attribute)
  end

  def comparison
    @record.send(options[:with])
           .send(attribute)
  end

  def equals?(val, oth)
    val = val.to_s if val.is_a? Symbol
    oth = oth.to_s if oth.is_a? Symbol
    val == oth
  end

end
