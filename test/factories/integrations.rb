FactoryBot.define do
  factory :integration do
    nature             { "mes_parcelles"}
    parameters         {{ siret_number: '12345678910111', username: 'Ekylibre', password: 'Duke2018$', harvest_year: '2020' }}
  end
end
