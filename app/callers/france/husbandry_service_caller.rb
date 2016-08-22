module France
  # Example/Test of a Caller
  class HusbandryServiceCaller < ActionCaller::Base
    calls :get_my_herd, :add_my_herd

    def get_my_herd(herd_number)
      # Transcodage
      get_html('http://test.ekylibre.lan:3000/backend/dashboards/stocks') do |r|
        Rails.logger.info herd_number

        r.success do
          Rails.logger.info "SUCCESS #{r.code}"
          # Transcodage
        end

        r.redirect do
          Rails.logger.info "REDIRECT #{r.code}"
          r.error :redirect
        end

        r.error do
          Rails.logger.info "ERROR #{r.code}"
        end

        Rails.logger.info r.state.to_s.blue
      end
    end

    def add_my_herd(herd_number, individuals)
      post_json('http://test.ekylibre.lan:3000/backend/dashboards/stocks', herd: herd_number.to_s, individuals: individuals.to_s) do |r|
        r.success do
          Rails.logger.info 'SUCCESS'
        end
      end
    end
  end
end
