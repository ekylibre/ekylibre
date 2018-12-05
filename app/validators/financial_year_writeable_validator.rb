class FinancialYearWriteableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value

    financial_year = financial_year(record, value)

    record.errors.add(attribute, :not_opened_financial_year) if financial_year.closed?
    record.errors.add(attribute, :financial_year_matching_this_date_is_closing) if financial_year.closing?
    record.errors.add(attribute, :financial_year_matching_this_date_is_in_closure_preparation) if financial_year.closure_in_preparation? && financial_year.closer.id != record.creator_id
  end

  def financial_year(record, value)
    return record.financial_year if record.respond_to?(:financial_year)
    FinancialYear.on(value)
  end
end
