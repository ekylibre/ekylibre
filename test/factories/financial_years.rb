FactoryBot.define do
  factory :financial_year do
    tax_declaration_mode { 'debit' }
    tax_declaration_frequency { 'yearly' }
    started_on { '01/01/1994' }
    stopped_on { '31/12/1994' }
  end
end
