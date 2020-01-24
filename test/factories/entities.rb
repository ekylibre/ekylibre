FactoryBot.define do
  factory :entity do
    active { true }
    client { false }
    employee { false }
    locked { false }
    of_company { false }
    prospect { false }
    reminder_submissive { false }
    supplier { false }
    transporter { false }
    vat_subjected { true }
    currency { 'EUR' }
    language { 'fra' }
    nature { 'contact' }
    sequence(:full_name) { |n| "full name #{n}" }
    sequence(:last_name) { |n| "last name #{n}" }
    country { 'fr' }
    iban { '' }

    trait :accountant do
    end

    trait :client do
      client { true }
      after(:build) do |entity|
        entity.client_account = create :account, :client
      end
    end

    trait :supplier do
      supplier { true }
      after(:build) do |entity|
        entity.supplier_account = create :account, :supplier
      end
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

    trait :transporter do
      transporter { true }
    end
  end
end
