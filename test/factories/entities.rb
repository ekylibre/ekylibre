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
    full_name { 'Dupond Comptable' }
    last_name { 'Dupond' }
    country { 'fr' }
    iban { '' }

    trait :accountant do
    end

    trait :client do
      client { true }
      after(:build) do |entity|
        entity.client_account = Account.find_by!(number: '411')
      end
    end

    trait :supplier do
      supplier { true }
      after(:build) do |entity|
        entity.supplier_account = Account.find_by!(number: '401')
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
  end
end
