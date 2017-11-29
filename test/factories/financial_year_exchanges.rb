FactoryGirl.define do
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
