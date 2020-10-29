class DateIsEndOfMonthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless Date.parse(value) == Date.parse(value).end_of_month
      record.errors.add(attribute, :should_be_the_last_day_of_month)
    end
  end
end
