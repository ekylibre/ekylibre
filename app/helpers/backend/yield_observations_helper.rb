module Backend
  module YieldObservationsHelper
    def plant_crit(*args)
      list_crit(:plant_id,
                :plant.tl,
                [[]] + plants_used_in_observations.collect { |u| [u.name, u.id] }.sort)
    end

    def activity_crit(*args)
      list_crit(:activity_id,
                Activity.model_name.human,
                [[]] + activities_used_in_observations.collect { |u| [u.name, u.id] }.sort)
    end

    private

      def plants_used_in_observations
        YieldObservation.all.map(&:plants).flatten.uniq
      end

      def activities_used_in_observations
        YieldObservation.all.map(&:activity).uniq
      end
  end
end
