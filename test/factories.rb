FactoryGirl.define do
  factory :entity do
    active true
    client false
    employee false
    locked false
    of_company false
    prospect false
    reminder_submissive false
    supplier false
    transporter false
    vat_subjected true
    currency 'EUR'
    language 'fra'
    nature 'contact'
    full_name "Dupond Comptable"
    last_name "Dupond"
    country 'fr'
    iban ''

    trait :accountant do
    end

    trait :with_booked_journals do
      after(:create) do |entity|
        create_list :journal, 2, :various, accountant_id: entity.id
      end
    end
  end

  factory :journal do
    closed_on Date.parse('1997-12-31')
    sequence(:name) { |i| "Journal #{i}" }
    sequence(:code) { |i| "OP#{i}" }
    currency 'EUR'
    nature 'various'
    used_for_affairs true
    used_for_gaps true
    used_for_permanent_stock_inventory false
    used_for_tax_declarations false
    used_for_unbilled_payables false

    trait :various do
    end
  end

  factory :financial_year_exchange do
    # needs financial_year

    after(:build) do |exchange|
      exchange.started_on = exchange.financial_year.started_on
      exchange.stopped_on = exchange.financial_year.stopped_on - 1.month
      exchange.closed_at = exchange.stopped_on
    end

    trait :opened do
      after(:build) do |exchange|
        exchange.closed_at = nil
      end
    end
  end
end
