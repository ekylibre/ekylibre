# encoding: UTF-8
require 'test_helper'

class Ekylibre::EdnotifTest < ActiveSupport::TestCase

  setup do
    args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
             company_code: 'E010',
             #geo: '',
             app_name: 'Ekylibre',
             ednotif_service_name: 'IpBNotif',
             ednotif_site_service_code: '9',
             ednotif_site_version_code: '9',
             ednotif_site_version: '1.00',
             user_id: 'ekylibrt33d',
             user_password: 'hf4y3c6tY'
    }

    @tr = ::Tele::Idele::Ednotif.new args
  end

=begin
  test 'manually retrieving urls from Reswel' do
    @tr.get_urls

    assert_not_empty(@tr.instance_variable_get('@business_wsdl'))
    assert_not_empty(@tr.instance_variable_get('@customs_wsdl'))

  end
=end


=begin
  test 'raising missing wsdl exception while retrieving urls from Reswel' do


    args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
               company_code: 'E999', #Hacked company code for throwing exception
               geo: '',
               app_name: 'Ekylibre',
               ednotif_service_name: 'IpBNotif',
               ednotif_site_service_code: '9',
               ednotif_site_version_code: '9',
               ednotif_site_version: '1.00',
               user_id: 'ekylibrt33d',
               user_password: 'hf4y3c6tY'
      }

    tr2 = ::Tele::Idele::Ednotif.new args

    exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ tr2.get_urls }
    assert_equal('Missing WSDL urls in xml from Reswel get url', exception.message)

  end
=end
=begin

  test 'raising soap fault exception while retrieving urls from Reswel' do

    args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
               company_code: '', #Hacked company code for throwing exception
               geo: '',
               app_name: 'Ekylibre',
               ednotif_service_name: 'IpBNotif',
               ednotif_site_service_code: '9',
               ednotif_site_version_code: '9',
               ednotif_site_version: '1.00',
               user_id: 'ekylibrt33d',
               user_password: 'hf4y3c6tY'
      }

    tr2 = ::Tele::Idele::Ednotif.new args

    exception = assert_raise(::Tele::Idele::EdnotifError::SOAPError){ tr2.get_urls }
    assert_equal("cvc-datatype-valid.1.2.1: '' is not a valid value for 'NMTOKEN'.", exception.message)

  end
=end


=begin
  test 'manually retrieving token from Reswel' do

    @tr.instance_variable_set( '@customs_wsdl', 'https://zoe.cmre.fr/wsguichet/WsGuichet?wsdl' )
    @tr.get_token
    assert_not_empty(@tr.instance_variable_get('@token'))

  end
=end
=begin

  test 'raising soap fault exception while retrieving token from Reswel' do

    args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
             company_code: 'E010',
             # geo: '',
             app_name: 'Ekylibre',
             ednotif_service_name: 'IpBNotif',
             ednotif_site_service_code: '9',
             ednotif_site_version_code: '9',
             ednotif_site_version: '1.00',
             user_id: 'fakeUserIdTest', #Hacked user id for throwing exception
             user_password: 'hf4y3c6tY'
    }

    tr2 = ::Tele::Idele::Ednotif.new args

    tr2.instance_variable_set( '@customs_wsdl', 'https://zoe.cmre.fr/wsguichet/WsGuichet?wsdl' )

    exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ tr2.get_token }
    assert_equal('Aucune personne trouvée correspondant à (login) = (fakeUserIdTest)', exception.message)

  end
=end
=begin

  test 'automatic authentication to Reswel' do

    authenticated = @tr.authenticate

    assert(authenticated)
    assert_not_empty(@tr.instance_variable_get('@business_wsdl'))
    assert_not_empty(@tr.instance_variable_get('@customs_wsdl'))
    assert_not_empty(@tr.instance_variable_get('@token'))

  end
=end

=begin

  test 'raising exception animal already entered while creating cattle entrance on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3312345678',
               entry_date: '2015-02-13',
               entry_reason: 'A',
               src_country_code: 'FR',
               src_farm_number: '01000000',
               src_owner_name: 'EKYLIBRE_TEST',
               prod_code: nil,
               cattle_categ_code: nil
      }


      exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_entrance args }
      assert_equal('9lpBM025', exception.code)

    end

  end
=end

=begin

  test 'passing creation cattle entrance on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3300000005',
               entry_date: '2015-02-17',
               entry_reason: 'A',
               src_country_code: 'FR',
               src_farm_number: '01000000',
               src_owner_name: 'EKYLIBRE_TEST',
               prod_code: nil,
               cattle_categ_code: nil
      }

      status = @tr.create_cattle_entrance args

      assert_equal('waiting validation', status)

    end

  end
=end



=begin
  test 'passing creation cattle exit on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3300000004',
               exit_date: '2015-02-17',
               exit_reason: 'H',
               dest_country_code: 'FR',
               dest_farm_number: '01000000',
               dest_owner_name: 'EKYLIBRE_TEST_DEST'
      }

      status = @tr.create_cattle_exit args

      assert_equal('validated', status)

    end

  end
=end

=begin
  test 'raising exception animal already exited while creating cattle exit on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3300000005',
               exit_date: '2015-02-17',
               exit_reason: 'H',
               dest_country_code: 'FR',
               dest_farm_number: '01000000',
               dest_owner_name: 'EKYLIBRE_TEST_DEST'
      }

      exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_exit args }

      assert_equal('9lpBM010', exception.code)


    end

  end
=end
=begin

  test 'passing creation cattle new birth on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3300000004',
               sex: 'M',
               race_code: '',
               birth_date: '',
               work_number: '',
               cattle_name: '',
               transplant: '',
               abortion: '',
               twin: '',
               birth_condition: '',
               birth_weight: '',
               weighed: '',
               bust_size: '',
               mother_animal_country_code: '',
               mother_animal_id: '',
               mother_race_code: '',
               father_animal_country_code: '',
               father_animal_id: '',
               father_race_code: '',
               passport_ask: '',
               prod_code: ''
      }

      status = @tr.create_cattle_exit args

      assert_equal('validated', status)

    end

  end
=end

end
