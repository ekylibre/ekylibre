module Backend
  class GolumnsController < Backend::BaseController
    # Save golumn config in preferences
    def update
      unless params['positions'].nil?
        positions = params['positions'].sort do |a, b|
          a[0] <=> b[0]
        end.map do |group|
          next unless group.second['id'] && !group.second['id'].to_i.zero?
          g = { id: group.second['id'].to_i }
          if group.second['containers']
            g[:containers] = group.second['containers'].map(&:to_i)
          end
          g
        end.compact
        begin
          current_user.prefer!("golumn.#{params[:id]}", { positions: positions }.deep_stringify_keys.to_yaml)
          head :ok
        rescue ActiveRecord::StaleObjectError
          head :locked
        end
      end
    end

    def show
      preference = current_user.preference("golumn.#{params[:id]}", {}.to_yaml)
      render json: YAML.safe_load(preference.value)
    end

    def reset
      if preference = current_user.preferences.find_by(name: "golumn.#{params[:id]}")
        preference.destroy!
      end
      head :ok
    end
  end
end
