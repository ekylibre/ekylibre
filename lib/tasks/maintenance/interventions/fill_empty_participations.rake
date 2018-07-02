# Tenant tasks
namespace :maintenance do
  namespace :intervention do
    desc 'Fill participations where interventions have no participations but doers'
    task fill_empty_participations: :environment do
      tenant = ENV['TENANT']

      raise 'Need TENANT variable' unless tenant

      puts "Switch to tenant #{tenant}"
      Ekylibre::Tenant.switch(tenant) do
        doers_without_participations = InterventionDoer.with_empty_participations

        Interventions::Participations::FillEmptyParticipationsInteractor
          .call({ intervention_agents: doers_without_participations })
      end
    end

    desc 'Count participations where interventions have no participations but doers'
    task count_empty_participations: :environment do
      tenant = ENV['TENANT']

      raise 'Need TENANT variable' unless tenant

      puts "Switch to tenant #{tenant}"
      Ekylibre::Tenant.switch(tenant) do
        puts "Interventions without participations: #{ InterventionDoer.with_empty_participations.count }"
      end
    end
  end
end