class FinancialYearCloseJob < ActiveJob::Base
  queue_as :default

  def perform(financial_year, closer, to_close_on, result_journal_id:, forward_journal_id:, closure_journal_id:)
    to_close_on = Date.parse to_close_on
    if financial_year.close(closer,
                            to_close_on,
                            result_journal_id: result_journal_id,
                            forward_journal_id: forward_journal_id,
                            closure_journal_id: closure_journal_id)
      closer.notify(:financial_year_x_successfully_closed, name: financial_year.name)
    else
      financial_year.update_attributes(state: 'opened')
      closer.notify(:financial_year_x_could_not_be_closed, name: financial_year.name)
    end
  end
end
