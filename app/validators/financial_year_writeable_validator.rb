# frozen_string_literal: true

class FinancialYearWriteableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    financial_year = financial_year(record, value)

    return record.errors.add(attribute, :financial_year_not_found) unless financial_year

    if financial_year.closing?
      record.errors.add(attribute, :financial_year_matching_this_date_is_closing)
    elsif financial_year.closure_in_preparation?
      record.errors.add(attribute, :financial_year_matching_this_date_is_in_closure_preparation) if financial_year.closer.id != record.updater_id
    else
      record.errors.add(attribute, :not_opened_financial_year) unless financial_year.opened?
    end
  end

  def financial_year(record, value)
    return record.financial_year if record.respond_to?(:financial_year)

    FinancialYear.on(value)
  end
end
