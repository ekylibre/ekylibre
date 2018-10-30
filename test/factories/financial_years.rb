FactoryBot.define do
  factory :financial_year do
    tax_declaration_mode { 'debit' }
    tax_declaration_frequency { 'yearly' }
    started_on { '01/01/1994' }
    stopped_on { '31/12/1994' }

    after(:build) do |year|
      year.code = year.default_code if year.started_on && year.stopped_on && year.code.blank?
      year.currency = 'EUR'
    end

    trait :skip_validate do
      to_create { |instance| instance.save(validate: false)}
    end
  end
end
