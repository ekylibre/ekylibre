FactoryBot.define do
  factory :financial_year do
    transient do
      year { nil }
      month { 1 }
      day { 1 }
    end

    tax_declaration_mode { 'debit' }
    tax_declaration_frequency { 'yearly' }
    started_on { Date.new year, month, day }
    stopped_on { started_on + 1.year - 1.day }
    currency { :EUR }
    state { :opened }

    after(:build) do |year|
      year.code = year.default_code if year.started_on && year.stopped_on && year.code.blank?
    end

    trait :skip_validate do
      to_create { |instance| instance.save(validate: false) }
    end
  end
end
