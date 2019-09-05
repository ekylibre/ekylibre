namespace :maintenance do
  namespace :interventions do
    desc 'Add missing intervention costings for all interventions'
    task update_costings: :environment do
      Ekylibre::Tenant.switch_each do
        puts "Updating #{Intervention.count} interventions in #{Ekylibre::Tenant.current}"
        Intervention.find_each(&:create_missing_costing)
      end
    end
  end
end
