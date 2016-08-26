module InspectionViewable
  extend ActiveSupport::Concern

  included do
    before_action :set_preference_view, only: [:show]
    hide_action :set_preference_view
  end

  def set_preference_view
    if params[:unit] && params[:activity_id]
      activity = Activity.find(params[:activity_id])
      activity.unit_preference(current_user, params['unit'])
    end
  end
end
