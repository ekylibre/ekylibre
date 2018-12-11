class DateFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      Date.parse(value)
    rescue ArgumentError
      record.errors.add(attribute, :invalid_date)
    end
  end
end
