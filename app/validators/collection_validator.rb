class CollectionValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.nil? || !value.kind_of?(Array)
      record.errors.add(attribute, :invalid)
    elsif value.any?(&:invalid?)
      record.errors.add(attribute, :invalid_child)
    end
  end
end
