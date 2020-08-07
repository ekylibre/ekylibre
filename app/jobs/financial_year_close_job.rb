class FinancialYearCloseJob < ApplicationJob
  queue_as :default

  def perform(financial_year, closer, to_close_on, allocations, result_journal_id:, forward_journal_id:, closure_journal_id:)
    to_close_on = Date.parse to_close_on
    if financial_year.close(closer,
                            to_close_on,
                            allocations: allocations,
                            result_journal_id: result_journal_id,
                            forward_journal_id: forward_journal_id,
                            closure_journal_id: closure_journal_id
                            )
    else
      financial_year.update_columns(state: 'opened')
      FileUtils.rm_rf Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', "#{financial_year.id}")
    end
  end
end
