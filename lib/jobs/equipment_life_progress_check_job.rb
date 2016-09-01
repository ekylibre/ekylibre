class EquipmentLifeProgressCheckJob < ActiveJob::Base
  queue_as :default

  def perform
    Ekylibre::Tenant.switch_each do
      alert_ratio = 0.85 # Ratio over 1, not 100%

      ratios = Hash.new { Hash.new(alert_ratio) }

      # Equipments whose lifespan is under alert ratio
      lifeworn_equipments = Equipment.select do |e|
        e.lifespan_progress > ratios[:equip][:life]
      end

      # Equipments whose working_lifespan is under alert ratio
      workworn_equipments = Equipment.select do |e|
        e.working_lifespan_progress > ratios[:equip][:work]
      end

      lifeworn_equipments.each(&:alert_life)
      workworn_equipments.each(&:alert_work)

      worn_equipments = lifeworn_equipments + workworn_equipments

      Equipment.where.not(id: worn_equipments.map(&:id)).each do |equip|
        # Components whose lifespan is under alert ratio
        lifeworn_components = equip.components.select do |component|
          equip.lifespan_progress_of(component) > ratios[:comp][:life]
        end

        # Components whose working_lifespan is under alert ratio
        workworn_components = equip.components.select do |component|
          equip.working_lifespan_progress_of(component) > ratios[:comp][:work]
        end

        lifeworn_components.each { |c| equip.alert_component_life(c) }
        workworn_components.each { |c| equip.alert_component_work(c) }
      end
    end
  end
end
