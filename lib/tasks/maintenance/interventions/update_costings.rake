# This script use STI, so, you can not use it in terminal :
#  `bin/rake maintenance:interventions:update_costings`
# Instead of, use it with bin/rails runner.
# Do not forget to load taks. So you can use something like :
#   `bin/rails runner "Ekylibre::Application.load_tasks; Rake::Task['maintenance:interventions:update_costings'].invoke;"`
namespace :maintenance do
  namespace :interventions do
    desc 'Update all intervention costings'
    task update_costings: :environment do
      Ekylibre::Tenant.switch_each do
        puts "Updating #{Intervention.count} interventions in #{Ekylibre::Tenant.current}"
        Intervention.find_each(&:update_costing)
      end
    end
  end
end
