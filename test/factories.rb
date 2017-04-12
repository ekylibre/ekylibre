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
    full_name 'Dupond Comptable'
    last_name 'Dupond'
    country 'fr'
    iban ''

    trait :accountant do
    end

    trait :with_booked_journals do
      after(:create) do |entity|
        create_list :journal, 2, :various, accountant_id: entity.id
      end
    end

    trait :with_email do
      after(:create) do |entity|
        create :entity_address, :email, entity: entity
      end
    end
  end

  factory :entity_address do
    entity
    canal 'email'
    by_default true
    mail_auto_update false
    sequence(:coordinate) { |n| "email#{n}@test.com" }

    trait :email do
    end
  end

  factory :account do
    debtor false
    reconcilable false
    sequence(:name) { |n| "801 - Compte #{n}" }
    sequence(:number) { |n| "801000000#{n}" }
  end

  factory :cash do
    account
    journal
    bank_account_holder_name 'Dupond'
    bank_account_key ''
    bank_account_number ''
    bank_agency_code ''
    bank_code ''
    bank_identifier_code 'GHBXFRPP'
    bank_name 'GHB'
    country 'fr'
    currency 'EUR'
    iban ''
    spaced_iban ''
    mode 'iban'
    nature 'bank_account'
    sequence(:name) { |n| "Bank account #{n}" }
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

    trait :bank do
      nature 'bank'
    end

    trait :with_cash do
      after(:create) do |journal|
        create(:cash, journal: journal)
      end
    end
  end

  factory :journal_entry do
    journal
    absolute_credit 0
    absolute_debit 0
    absolute_currency 'EUR'
    credit 0
    debit 0
    balance 0
    currency 'EUR'
    real_credit 0
    real_debit 0
    real_balance 0
    real_currency 'EUR'
    real_currency_rate 1.0
    state 'draft'
    printed_on Date.parse('2016-12-01')

    trait :draft do
    end

    trait :confirmed do
      state 'confirmed'
    end

    trait :with_items do
      after(:build) do |entry|
        2.times do
          attributes = attributes_for(:journal_entry_item)
          attributes.update account: create(:account), printed_on: entry.printed_on
          entry.items.build attributes
        end
      end
    end
  end

  factory :journal_entry_item do
    association :entry, factory: %i[journal_entry with_items]
    account
    absolute_credit 0
    absolute_debit 0
    absolute_pretax_amount 0
    cumulated_absolute_credit 0
    cumulated_absolute_debit 0
    absolute_currency 'EUR'
    credit 0
    debit 0
    pretax_amount 0
    balance 0
    currency 'EUR'
    real_credit 0
    real_debit 0
    real_pretax_amount 0
    real_balance 0
    real_currency 'EUR'
    real_currency_rate 1.0
    state 'confirmed'
    sequence(:name) { |i| "JEI #{i}" }
    printed_on Date.parse('2016-12-01')
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
