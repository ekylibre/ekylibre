# frozen_string_literal: true

class DateFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value.split(/\D/).size == 3
      record.errors.add(attribute, :invalid_date)
    end

    begin
      Date.parse(value)
    rescue ArgumentError
      record.errors.add(attribute, :invalid_date)
    end
  end
end
