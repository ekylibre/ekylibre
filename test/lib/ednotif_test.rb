# encoding: utf-8
require 'test_helper'

class Ekylibre::EdnotifTest < ActiveSupport::TestCase
  setup do
    args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
             company_code: 'E010',
             # geo: '',
             app_name: 'Ekylibre',
             ednotif_service_name: 'IpBNotif',
             ednotif_site_service_code: '9',
             ednotif_site_version_code: '9',
             ednotif_site_version: '1.00',
             user_id: 'ekylibrt33d',
             user_password: 'hf4y3c6tY' }

    @tr = ::Tele::Idele::Ednotif.new args
  end

  #   test 'manually retrieving urls from Reswel' do
  #     @tr.get_urls
  #
  #     assert_not_empty(@tr.instance_variable_get('@business_wsdl'))
  #     assert_not_empty(@tr.instance_variable_get('@customs_wsdl'))
  #
  #   end

  #   test 'raising missing wsdl exception while retrieving urls from Reswel' do
  #
  #
  #     args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
  #                company_code: 'E999', #Hacked company code for throwing exception
  #                geo: '',
  #                app_name: 'Ekylibre',
  #                ednotif_service_name: 'IpBNotif',
  #                ednotif_site_service_code: '9',
  #                ednotif_site_version_code: '9',
  #                ednotif_site_version: '1.00',
  #                user_id: 'ekylibrt33d',
  #                user_password: 'hf4y3c6tY'
  #       }
  #
  #     tr2 = ::Tele::Idele::Ednotif.new args
  #
  #     exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ tr2.get_urls }
  #     assert_equal('Missing WSDL urls in xml from Reswel get url', exception.message)
  #
  #   end
  #
  #   test 'raising soap fault exception while retrieving urls from Reswel' do
  #
  #     args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
  #                company_code: '', #Hacked company code for throwing exception
  #                geo: '',
  #                app_name: 'Ekylibre',
  #                ednotif_service_name: 'IpBNotif',
  #                ednotif_site_service_code: '9',
  #                ednotif_site_version_code: '9',
  #                ednotif_site_version: '1.00',
  #                user_id: 'ekylibrt33d',
  #                user_password: 'hf4y3c6tY'
  #       }
  #
  #     tr2 = ::Tele::Idele::Ednotif.new args
  #
  #     exception = assert_raise(::Tele::Idele::EdnotifError::SOAPError){ tr2.get_urls }
  #     assert_equal("cvc-datatype-valid.1.2.1: '' is not a valid value for 'NMTOKEN'.", exception.message)
  #
  #   end

  #   test 'manually retrieving token from Reswel' do
  #
  #     @tr.instance_variable_set( '@customs_wsdl', 'https://zoe.cmre.fr/wsguichet/WsGuichet?wsdl' )
  #     @tr.get_token
  #     assert_not_empty(@tr.instance_variable_get('@token'))
  #
  #   end
  #
  #   test 'raising soap fault exception while retrieving token from Reswel' do
  #
  #     args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
  #              company_code: 'E010',
  #              # geo: '',
  #              app_name: 'Ekylibre',
  #              ednotif_service_name: 'IpBNotif',
  #              ednotif_site_service_code: '9',
  #              ednotif_site_version_code: '9',
  #              ednotif_site_version: '1.00',
  #              user_id: 'fakeUserIdTest', #Hacked user id for throwing exception
  #              user_password: 'hf4y3c6tY'
  #     }
  #
  #     tr2 = ::Tele::Idele::Ednotif.new args
  #
  #     tr2.instance_variable_set( '@customs_wsdl', 'https://zoe.cmre.fr/wsguichet/WsGuichet?wsdl' )
  #
  #     exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ tr2.get_token }
  #     assert_equal('Aucune personne trouvée correspondant à (login) = (fakeUserIdTest)', exception.message)
  #
  #   end
  #
  #   test 'automatic authentication to Reswel' do
  #
  #     authenticated = @tr.authenticate
  #
  #     assert(authenticated)
  #     assert_not_empty(@tr.instance_variable_get('@business_wsdl'))
  #     assert_not_empty(@tr.instance_variable_get('@customs_wsdl'))
  #     assert_not_empty(@tr.instance_variable_get('@token'))
  #
  #   end

  #
  #   test 'raising exception animal already entered while creating cattle entrance on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3312345678',
  #                entry_date: '2015-02-13',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'FR',
  #                src_farm_number: '01000000',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_entrance args }
  #       assert_equal('9lpBM025', exception.code)
  #
  #     end
  #
  #   end

  #
  #   test 'passing creation cattle entrance on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000005',
  #                entry_date: '2015-02-17',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'FR',
  #                src_farm_number: '01000000',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #       status = @tr.create_cattle_entrance args
  #
  #       assert_equal('waiting validation', status)
  #
  #     end
  #
  #   end

  #   test 'passing creation cattle exit on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000004',
  #                exit_date: '2015-02-17',
  #                exit_reason: 'H',
  #                dest_country_code: 'FR',
  #                dest_farm_number: '01000000',
  #                dest_owner_name: 'EKYLIBRE_TEST_DEST'
  #       }
  #
  #       status = @tr.create_cattle_exit args
  #
  #       assert_equal('validated', status)
  #
  #     end
  #
  #   end

  #   test 'raising exception animal already exited while creating cattle exit on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000005',
  #                exit_date: '2015-02-17',
  #                exit_reason: 'H',
  #                dest_country_code: 'FR',
  #                dest_farm_number: '01000000',
  #                dest_owner_name: 'EKYLIBRE_TEST_DEST'
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_exit args }
  #
  #       assert_equal('9lpBM010', exception.code)
  #
  #
  #     end
  #
  #   end
  #
  #   test 'passing creation cattle new birth on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000006',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                work_number: '0001',
  #                cattle_name: 'calypso',
  #                transplant: 'false',
  #                abortion: 'false',
  #                twin: 'false',
  #                birth_condition: '1',
  #                birth_weight: '25',
  #                weighed: 'false',
  #                bust_size: '393',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                passport_ask: 'false',
  #                prod_code: nil
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_cattle_new_birth args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'raising exception date invalid while creating cattle new birth on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000006',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-12-31', #hacked to raise exception
  #                work_number: '0001',
  #                cattle_name: 'calypso',
  #                transplant: 'false',
  #                abortion: 'false',
  #                twin: 'false',
  #                birth_condition: '1',
  #                birth_weight: '25',
  #                weighed: 'false',
  #                bust_size: '393',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                passport_ask: 'false',
  #                prod_code: nil
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_new_birth args }
  #
  #       assert_equal('9IpBI052', exception.code)
  #
  #     end
  #
  #   end

  #   test 'raising exception date invalid while creating cattle new still birth on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-12-31', #hacked to raise exception
  #                cattle_name: 'calypso',
  #                transplant: 'false',
  #                abortion: 'false',
  #                twin: 'false',
  #                birth_condition: '1',
  #                birth_weight: '25',
  #                weighed: 'false',
  #                bust_size: '393',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56'
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_new_stillbirth args }
  #
  #       assert_equal('9IpBI052', exception.code)
  #
  #     end
  #
  #   end

  #   test 'passing creation cattle new stillbirth on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                cattle_name: 'calypso',
  #                transplant: 'false',
  #                abortion: 'false',
  #                twin: 'false',
  #                birth_condition: '1',
  #                birth_weight: '25',
  #                weighed: 'false',
  #                bust_size: '393',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_cattle_new_stillbirth args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'passing creation switched animal on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000009',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                witness: '0',
  #                work_number: '0003',
  #                cattle_name: 'calypso',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                birth_farm_country_code: 'FR',
  #                birth_farm_number: '01000000',
  #                entry_date: '2015-02-18',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'FR',
  #                src_farm_number: '01000001',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_switched_animal args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'raising exception invalid data while creating switched animal on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000009',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                witness: '0',
  #                work_number: '0003',
  #                cattle_name: 'calypso',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                birth_farm_country_code: 'FR',
  #                birth_farm_number: '01000000',
  #                entry_date: '2015-02-18',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'FR',
  #                src_farm_number: '01000001',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_switched_animal args }
  #
  #       assert_equal('9IpBI001', exception.code)
  #
  #
  #     end
  #
  #   end

  #   test 'passing creation imported animal notice on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                src_animal_country_code: 'FR',
  #                src_animal_id: '3300000009'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_imported_animal_notice args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'raising exception invalid data while creating imported animal notice on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                src_animal_country_code: 'FR',
  #                src_animal_id: '3300000009'
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_imported_animal_notice args }
  #
  #       assert_equal('9IpBI049', exception.code)
  #
  #
  #     end
  #
  #   end
  #
  #   test 'passing creation imported animal on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000009',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                witness: '0',
  #                work_number: '0003',
  #                cattle_name: 'calypso',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                birth_farm_country_code: 'YE',
  #                birth_farm_number: '01000000',
  #                src_animal_country_code: 'YE',
  #                src_animal_id: '0000000009',
  #                entry_date: '2015-02-18',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'DE',
  #                src_farm_number: '01000001',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_switched_animal args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #
  #   test 'passing getting cattle list on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                start_date: '2015-01-01',
  #                end_date: '2015-02-18',
  #                stock: 'true'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         res = @tr.get_cattle_list args
  #
  #         assert_equal('validated', res[:status])
  #         assert_not_nil(res[:output_hash])
  #       end
  #
  #     end
  #
  #   end

  #
  #
  #   test 'passing getting case feedback on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                start_date: '2015-02-01'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         res = @tr.get_case_feedback args
  #
  #         assert_equal('validated', res[:status])
  #         assert_not_nil(res[:output_hash])
  #       end
  #
  #     end
  #
  #   end

  #
  #   test 'passing getting animal case on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000004'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         res = @tr.get_animal_case args
  #
  #         assert_equal('validated', res[:status])
  #         assert_not_nil(res[:output_hash])
  #       end
  #
  #     end
  #
  #   end
  #
  #   test 'passing getting presumed exit on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         res = @tr.get_presumed_exit args
  #
  #         assert_equal('validated', res[:status])
  #         assert_not_nil(res[:output_hash])
  #       end
  #
  #     end
  #
  #   end

  #   test 'passing create commande boucles on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000004',
  #                boucle_conventionnelle: 'true',
  #                boucle_travail: '',
  #                boucle_electronique: nil,
  #                cause_remplacement: 'C'
  #       }
  #
  #       #TODO !
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_commande_boucles args
  #
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'passing create rebouclage on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000004',
  #                boucle_conventionnelle: 'true',
  #                boucle_travail: '',
  #                boucle_electronique: nil,
  #                cause_remplacement: 'C'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_rebouclage args
  #
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end
end
