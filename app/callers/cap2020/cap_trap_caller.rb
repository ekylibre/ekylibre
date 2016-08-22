module Cap2020
  class CapTrapCaller < ActionCaller::Base
    calls :fetch_all_values

    def fetch_all_values(key, trap_model=:captrap)
      fetch_ruiner_values(key, 0, trap_model)
    end

    def fetch_ruiner_values(key, ruiner_id, trap_model=:captrap)
      get_html("http://sd-89062.dedibox.fr/Pieges/api/api_geojson.php?app_key=#{key}&id_rav=#{ruiner_id}&type_piege=#{trap_model}") do |r|
        r.success do
          response = JSON.parse(r.body)
          Rails.logger.debug "SUCCESS #{r.code}".green
          arr = response['features'].map do |feature|
            trap_num = feature['properties']['num_piege']
            ruiner = feature['properties']['ravageur']
            ruiner = feature['properties']['ravageur'].blank? ? "Aucun" : ruiner
            ruiner_count = feature['comptage']['total_ravageur']

            Rails.logger.debug "\tPiège #{trap_num}:".yellow
            Rails.logger.debug "\t\tRavageur : #{ruiner}".yellow
            Rails.logger.debug "\t\tTotal : #{ruiner_count}".yellow
            [trap_num, [[ruiner, ruiner_count]].to_h]
          end
          arr.to_h
        end

        r.redirect do
          Rails.logger.debug "REDIRECT #{r.code}".yellow
        end

        r.error do
          Rails.logger.debug "ERROR #{r.code}".red
        end
      end
    end
  end
end
