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

  test 'retrieving urls from Reswel' do
    @tr.get_urls

    assert_not_empty(@tr.instance_variable_get('@business_wsdl'))
    assert_not_empty(@tr.instance_variable_get('@customs_wsdl'))

  end


=begin
  test 'raising missing wsdl exceptions while retrieving urls from Reswel' do

    args = { directory_wsdl: 'http://zoe.cmre.fr:80/wsannuaire/WsAnnuaire?wsdl',
               company_code: 'E999',
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

      exception = assert_raise(::Tele::Idele::EdnotifError){ tr2.get_urls }
      assert_equal('Missing WSDL urls in xml response', exception.message)

  end
=end


  test 'retrieving token from Reswel' do

    @tr.instance_variable_set( '@customs_wsdl', 'https://zoe.cmre.fr/wsguichet/WsGuichet?wsdl' )
    @tr.get_token
    assert_not_empty(@tr.instance_variable_get('@token'))
    print @tr.instance_variable_get('@token')

    #SSLError: Peer certificate cannot be authenticated with given CA certificates
  end



end
