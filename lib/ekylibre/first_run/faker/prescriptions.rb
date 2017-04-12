module Ekylibre
  module FirstRun
    module Faker
      class Prescriptions < Base
        def run
          file = files.join('prescription.jpg')
          count :animal_prescriptions do |w|
            # import veterinary prescription in PDF
            document = Document.create!(key: '2100000303_prescription_001', name: 'prescription-2100000303', nature: 'prescription', file: File.open(file, 'rb'))

            # create a veterinary
            veterinary = Entity.create!(
              first_name: 'Veto',
              last_name: 'PONTO',
              nature: :contact,
              client: false,
              supplier: false
            )

            # create veterinary prescription with PDF and veterinary
            prescription = Prescription.create!(prescriptor: veterinary, reference_number: '2100000303')

            # Attach doc to prescription
            prescription.attachments.create!(document: document)

            # create an issue for all interventions on animals and update them with prescription and recommender
            Intervention.of_nature(:animal_illness_treatment).find_each do |intervention|
              # create an issue
              animal = intervention.product_parameters.of_role('animal_illness_treatment-target').first.actor
              started_at = (intervention.started_at - 1.day) || Time.zone.now
              nature = %i[mammite edema limping fever cough diarrhea].sample
              issue = Issue.create!(target_type: animal.class.name, target_id: animal.id, priority: 3, observed_at: started_at, nature: nature, state: %w[opened closed aborted].sample)
              # add prescription on intervention
              intervention.issue = issue
              intervention.prescription = prescription
              intervention.recommended = true
              intervention.recommender = veterinary
              intervention.save!
              w.check_point
            end
          end
        end
      end
    end
  end
end
