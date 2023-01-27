class CreateInterventionProposals < ActiveRecord::Migration[4.2]
  def change
    unless data_source_exists?(:intervention_proposals)
      create_table :intervention_proposals do |t|
        t.references :technical_itinerary_intervention_template, index: { name: :technical_itinerary_intervention_template_id }, foreign_key: true
        t.date :estimated_date
        t.decimal :area
        t.references :activity_production, index: true, foreign_key: true
        t.timestamps null: false
      end
    end
  end
end
