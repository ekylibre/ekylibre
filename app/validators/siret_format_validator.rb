class SiretFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :invalid) unless Luhn.valid?(value)
  end
end
