json.financial_years_count @financial_years.closables_or_lockables.count

json.are_two_financials_years_opened @financial_years.limit(2).order(started_on: :desc).all? { |fy| fy.opened? }
