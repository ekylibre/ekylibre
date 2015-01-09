module Edi
  module Idele

    ###### HIGH-LEVEL API #########

    def create_cattle_entrance( animal_country_code, animal_id, entry_date, entry_reason, src_country_code, src_farm_number, src_owner_name, prod_code, cattle_categ_code )
      #TODO
      authenticate

      #token, farm_country_code and farm_number could be retrieved from Ekylibre instance.
      create_entree( @token, @farm_country_code, @farm_number, animal_country_code, animal_id, entry_date, entry_reason, src_country_code, src_farm_number, src_owner_name, prod_code, cattle_categ_code  )


    end

    def create_cattle_exit
      #TODO
      authenticate

    end

  end
end
