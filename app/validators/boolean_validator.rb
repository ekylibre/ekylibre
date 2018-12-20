class BooleanValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value.kind_of?(TrueClass) || value.kind_of?(FalseClass)
      record.errors.add(attribute, :invalid)
    end
  end
end
