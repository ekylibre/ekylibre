class FinancialYearArchive < Ekylibre::Record::Base
  enumerize :timing, in: %i[prior_to_closure post_closure]
  belongs_to :financial_year
end
