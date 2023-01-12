require 'test_helper'

class CompanyInformationsServiceTest < Ekylibre::Testing::ApplicationTestCase
  test 'it returns the rights informations' do
    company_information = CompanyInformationsService.call(siren: '808534283')
    # because we could have timeout response
    if company_information.any?
      assert_equal 'EKYLIBRE', company_information.fetch(:company_name)
      assert_equal '4 RUE CHARLES DOMERCQ', company_information.fetch(:address)
      assert_equal '33130 BEGLES', company_information.fetch(:city)
      assert_equal Date.new(2014, 11, 20), company_information.fetch(:company_creation_date)
      assert_equal '62.01Z', company_information.fetch(:activity_code)
      assert_equal nil, company_information.fetch(:vat_number)
      assert_equal '80853428300037', company_information.fetch(:siret_number)
      assert_equal(-0.544371, company_information.fetch(:lng))
      assert_equal 44.818376, company_information.fetch(:lat)
    end
  end
end
