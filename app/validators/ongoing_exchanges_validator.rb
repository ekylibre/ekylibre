class OngoingExchangesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    if FinancialYearExchange.opened.where('? BETWEEN started_on AND stopped_on', value).exists?
      record.errors.add(attribute, :financial_year_exchange_on_this_period)
    end
  end
end
