FactoryBot.define do
  factory :idea_diagnostic do

    auditor factory: :entity
    campaign
    state { %i[idea_doing done].sample }
    sequence(:name) { |n| "Diagnostic Idea #{n}" }
    sequence(:code) { |n| "IDEA#{n}" }

  end
end
