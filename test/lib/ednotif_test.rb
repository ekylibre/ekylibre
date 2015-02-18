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
               src_farm_country_code: 'FR',
               src_farm_number: '01000000',
               src_farm_owner_name: 'EKYLIBRE_TEST',
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
               src_farm_country_code: 'FR',
               src_farm_number: '01000000',
               src_farm_owner_name: 'EKYLIBRE_TEST',
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
               animal_id: '3300000006',
               sex: 'M',
               race_code: '56',
               birth_date: '2015-02-18',
               work_number: '0001',
               cattle_name: 'calypso',
               transplant: 'false',
               abortion: 'false',
               twin: 'false',
               birth_condition: '1',
               birth_weight: '25',
               weighed: 'false',
               bust_size: '393',
               mother_animal_country_code: 'FR',
               mother_animal_id: '3300000004',
               mother_race_code: '56',
               father_animal_country_code: 'FR',
               father_animal_id: '3300000003',
               father_race_code: '56',
               passport_ask: 'false',
               prod_code: nil
      }

      assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
        status = @tr.create_cattle_new_birth args
        assert_equal('validated', status)
      end

    end

  end
=end


=begin
  test 'raising exception date invalid while creating cattle new birth on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3300000006',
               sex: 'M',
               race_code: '56',
               birth_date: '2015-12-31', #hacked to raise exception
               work_number: '0001',
               cattle_name: 'calypso',
               transplant: 'false',
               abortion: 'false',
               twin: 'false',
               birth_condition: '1',
               birth_weight: '25',
               weighed: 'false',
               bust_size: '393',
               mother_animal_country_code: 'FR',
               mother_animal_id: '3300000004',
               mother_race_code: '56',
               father_animal_country_code: 'FR',
               father_animal_id: '3300000003',
               father_race_code: '56',
               passport_ask: 'false',
               prod_code: nil
      }

      exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_new_birth args }

      assert_equal('9IpBI052', exception.code)

    end

  end
=end

=begin
  test 'raising exception date invalid while creating cattle new still birth on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               sex: 'M',
               race_code: '56',
               birth_date: '2015-12-31', #hacked to raise exception
               cattle_name: 'calypso',
               transplant: 'false',
               abortion: 'false',
               twin: 'false',
               birth_condition: '1',
               birth_weight: '25',
               weighed: 'false',
               bust_size: '393',
               mother_animal_country_code: 'FR',
               mother_animal_id: '3300000004',
               mother_race_code: '56',
               father_animal_country_code: 'FR',
               father_animal_id: '3300000003',
               father_race_code: '56'
      }

      exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_new_stillbirth args }

      assert_equal('9IpBI052', exception.code)

    end

  end
=end


=begin
  test 'passing creation cattle new stillbirth on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               sex: 'M',
               race_code: '56',
               birth_date: '2015-02-18',
               cattle_name: 'calypso',
               transplant: 'false',
               abortion: 'false',
               twin: 'false',
               birth_condition: '1',
               birth_weight: '25',
               weighed: 'false',
               bust_size: '393',
               mother_animal_country_code: 'FR',
               mother_animal_id: '3300000004',
               mother_race_code: '56',
               father_animal_country_code: 'FR',
               father_animal_id: '3300000003',
               father_race_code: '56'
      }

      assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
        status = @tr.create_cattle_new_stillbirth args
        assert_equal('validated', status)
      end

    end

  end
=end

=begin
  test 'passing creation switched animal on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3300000009',
               sex: 'M',
               race_code: '56',
               birth_date: '2015-02-18',
               witness: '0',
               work_number: '0003',
               cattle_name: 'calypso',
               mother_animal_country_code: 'FR',
               mother_animal_id: '3300000004',
               mother_race_code: '56',
               father_animal_country_code: 'FR',
               father_animal_id: '3300000003',
               father_race_code: '56',
               birth_farm_country_code: 'FR',
               birth_farm_number: '01000000',
               entry_date: '2015-02-18',
               entry_reason: 'A',
               src_farm_country_code: 'FR',
               src_farm_number: '01000001',
               src_farm_owner_name: 'EKYLIBRE_TEST',
               prod_code: nil,
               cattle_categ_code: nil
      }

      assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
        status = @tr.create_switched_animal args
        assert_equal('validated', status)
      end

    end

  end
=end


=begin
  test 'raising exception invalid data while creating switched animal on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3300000009',
               sex: 'M',
               race_code: '56',
               birth_date: '2015-02-18',
               witness: '0',
               work_number: '0003',
               cattle_name: 'calypso',
               mother_animal_country_code: 'FR',
               mother_animal_id: '3300000004',
               mother_race_code: '56',
               father_animal_country_code: 'FR',
               father_animal_id: '3300000003',
               father_race_code: '56',
               birth_farm_country_code: 'FR',
               birth_farm_number: '01000000',
               entry_date: '2015-02-18',
               entry_reason: 'A',
               src_farm_country_code: 'FR',
               src_farm_number: '01000001',
               src_farm_owner_name: 'EKYLIBRE_TEST',
               prod_code: nil,
               cattle_categ_code: nil
      }

      exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_switched_animal args }

      assert_equal('9IpBI001', exception.code)


    end

  end
=end


=begin
  test 'passing creation imported animal notice on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               src_animal_country_code: 'FR',
               src_animal_id: '3300000009'
      }

      assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
        status = @tr.create_imported_animal_notice args
        assert_equal('validated', status)
      end

    end

  end
=end

=begin
  test 'raising exception invalid data while creating imported animal notice on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               src_animal_country_code: 'FR',
               src_animal_id: '3300000009'
      }

      exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_imported_animal_notice args }

      assert_equal('9IpBI049', exception.code)


    end

  end
=end
=begin

  test 'passing creation imported animal on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               animal_country_code: 'FR',
               animal_id: '3300000009',
               sex: 'M',
               race_code: '56',
               birth_date: '2015-02-18',
               witness: '0',
               work_number: '0003',
               cattle_name: 'calypso',
               mother_animal_country_code: 'FR',
               mother_animal_id: '3300000004',
               mother_race_code: '56',
               father_animal_country_code: 'FR',
               father_animal_id: '3300000003',
               father_race_code: '56',
               birth_farm_country_code: 'YE',
               birth_farm_number: '01000000',
               src_animal_country_code: 'YE',
               src_animal_id: '0000000009',
               entry_date: '2015-02-18',
               entry_reason: 'A',
               src_farm_country_code: 'DE',
               src_farm_number: '01000001',
               src_farm_owner_name: 'EKYLIBRE_TEST',
               prod_code: nil,
               cattle_categ_code: nil
      }

      assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
        status = @tr.create_switched_animal args
        assert_equal('validated', status)
      end

    end

  end
=end


  test 'passing getting cattle list on Ednotif' do

    authenticated = @tr.authenticate

    if authenticated

      args = { farm_country_code: 'FR',
               farm_number: '01999999',
               start_date: '2015-01-01',
               end_date: '2015-02-18',
               stock: 'true'
      }

      assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
        status = @tr.get_cattle_list args
        assert_equal('validated', status)
      end

    end

  end

=begin

  test 'base64 and zip' do

    messageZip='UEsDBBQACAAIAI9wUkYAAAAAAAAAAAAAAAAOAAAARlIwMTk5OTk5OS54bWztnWtzHDeWpr/Pr0D0145qAwf3jhlt0BItVy9FaijKMT3fuHZ1L2N1C0n2uP/9ZhYpkpWVRScTyORB4qU0HZ4SisU8xIMH14N//1+/v38nftt8/nL18cN//En9Rf5JbD78/PGXqw///I8/vb34YRX+JL58vfzwy+W7jx82//Gnf22+/Ol/Pfu3f//whf76avPly+U/N+tP359+/Hr1j5ebr+sPv20+fL28+rwRzff98OU//vR/v3799Nfvvvuf//mfv/zjanP5l4+f//nd13992nz57k/XRf7afKedYle/bN5t/vKPz9/916uT7978/H837y+/+9OzfxPN1/ZT1x/+8fHz+8uvzQ/85eYnuP7X2xIvLr9uftz8+nnzcvNh83lb8hlJZVeSVipcKPNXaf6q1V+si3+W6q9S/vt3h962+42Pf//07uPV184/3f7z84+/bF5f/uvLsx/Or7/j7Qv7ZU9/fb/5/HHnG0oVt1/X7+0pcPfDfHf4p7mNwIvN//n1a/vcZiVV8/fuIa//Zf8dP1zdj9Nd+fb13dJvvn78+f99//HXn99tvjz7+vnXzXXhnZf/7e4nPfgr236z7z/+dvXhS+cTti/2xG39S1PBrr5uev79ofeO+T31/L5Ot89w+a75XUkpndTR3v9t3f7z/s/13QM/2HVIN79vnr26iWP73/3FLhp2zi9/vmo+RN3U23sv9b+n/R2eXl41cf/wc8/33Sl3W2FId9l44J0Xm/cfrz48//j+07vN119/2Tz79qN1Xz8QmD/4CW9am8+b1x8/f938+uWhH+WBX/5tmUdWgNv37VUCpSQFZcKwSnD3vH9UQx/7W/7ujwO0/b6vmyLr1y95hM/bhiFJ3nsW4TsYm72mfwhL49uYkU7YfZgBP+5N03y4Pf1WY66an/zL68+bL03HYNPz898v963YA095/OHr582BAreF2gbhpuDhBmnQd3p+2eBwU/L05ldx76UHatmDJbbNdAPb1ZAnuSl4+EkGfaftj31T8tW9J3nozTc+OVDituIf/tXtFOmrBb1EFqVwt0yF00p6KLz7vkMKpwkdZMNSFd6ET0uKkkkPCArnrPC+BqlMhfc9CRTeKTOfws233wMUPrnCTz++v47fq/XL07Mb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'

    stream = ::Base64.decode64(messageZip)

    Zip::File.open_buffer(stream) do |f|

      f.each do |entry|
        puts "ext: #{entry.name}"

        content = entry.get_input_stream.read
        xml = Nokogiri::XML(content)
        print xml.inspect
      end
    end
  end
=end


end
