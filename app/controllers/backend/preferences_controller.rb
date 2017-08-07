module Backend
  class PreferencesController < Backend::BaseController
    def update
      name = permitted_preference
      unless name
        head :not_found
        return
      end
      preference = current_user.preferences.find_or_initialize_by(name: name)
      preference.nature = User::PREFERENCES[name]
      preference.value = case preference.nature
                         when /^boolean$/
                           %w[true TRUE 1 t].include?(params[:value])
                         when /^decimal$/
                           params[:value].to_d
                         when /^integer$/
                           params[:value].to_i
                         else
                           params[:value]
                         end
      preference.save!
      render nothing: true
    end

    protected

    def permitted_preference
      User::PREFERENCES.keys.detect { |p| p == params[:id] }
    end
  end
end
