FactoryBot.define do
  factory :document_template do
    active { true }
    by_default { true }
    managed { true }
    language { :fra }
    archiving { :last }

    factory :fec_data_error_template do
      name { "Fichier d'erreurs de données FEC" }
      nature { :fec_data_error }
    end

    factory :fec_structure_error_template do
      name { "Fichier d'erreurs de structure FEC" }
      nature { :fec_structure_error }
    end
  end
end
