module Ekylibre
  module Tele
    module Idele
      ###### HIGH-LEVEL API #########

      def create_cattle_entrance(_animal_country_code, _animal_id, _entry_date, _entry_reason, _src_country_code, _src_farm_number, _src_owner_name, _prod_code, _cattle_categ_code)
        # TODO
        authenticate

        # token, farm_country_code and farm_number could be retrieved from Ekylibre instance.
        # create_cattle_entrance( @token, @farm_country_code, @farm_number, animal_country_code, animal_id, entry_date, entry_reason, src_farm_country_code, src_farm_number, src_farm_owner_name, prod_code, cattle_categ_code  )
      end

      def create_cattle_exit
        # TODO
        authenticate
      end

      def Initialize
        # if service = NetService.find_by(reference_name: :synel)
        #  synel_first_part = service.identifiers.find_by(nature: :synel_username).value.to_s
        #  synel_second_part = Identifier.find_by(nature: :cattling_number).value.to_s
        #  synel_last_part = "IP"
        #  synel_file_extension = ".csv"
        # else

        # end
      end
    end
  end
end
