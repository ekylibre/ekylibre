module Backend
  class VegetalActivitiesController < Backend::ActivitiesController

    def show
      return unless @vegetal_activity = find_and_check
      t3e @vegetal_activity
    end

  end
end
