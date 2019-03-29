FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test#{n}@gmail.com" }
    password { '12345678' }
    sequence(:first_name) { |n| "Toto#{n}" }
    sequence(:last_name) { |n| "Dupont#{n}" }
    administrator { true }
  end
end
