require 'test_helper'

class CompanyInformationsServiceTest < Ekylibre::Testing::ApplicationTestCase
  setup do
    # `cassette_library_dir` est une configuration globale, et
    # `pfi_client_api_test` la déplace dans son propre `setup` sans la remettre :
    # on la repose donc ici, sans quoi l'ordre des tests décide du répertoire.
    VCR.configure do |config|
      config.cassette_library_dir = 'test/cassettes'
      config.default_cassette_options = {
        serialize_with: :yaml,
        record: :once,
        allow_playback_repeats: true,
        decode_compressed_response: true
      }
    end
  end

  test 'it returns the rights informations' do
    # Deux appels réseau — l'API Sirene de l'INSEE puis la base adresse
    # nationale — rejoués depuis une cassette. Sans elle, ce test n'aboutissait
    # que là où `INSEE_SIRENE_API_KEY` est renseignée : en CI l'appel échouait,
    # le service rendait `{}` et le `fetch` levait `KeyError: :company_name`.
    # Les données de l'INSEE changent par ailleurs à chaque mise à jour du
    # répertoire, ce qu'une assertion sur une adresse ne peut pas suivre.
    company_information = VCR.use_cassette('company_informations_service') do
      CompanyInformationsService.call(siren: '808534283')
    end

    assert_equal 'EKYLIBRE', company_information.fetch(:company_name)
    assert_equal '8 RUE DU BOUIL BLEU', company_information.fetch(:address)
    assert_equal '17250 SAINT-PORCHAIRE', company_information.fetch(:city)
    assert_equal Date.new(2014, 11, 20), company_information.fetch(:company_creation_date)
    assert_equal '62.01Z', company_information.fetch(:activity_code)
    assert_nil company_information.fetch(:vat_number)
    assert_equal '80853428300045', company_information.fetch(:siret_number)
    assert_equal(-0.783794, company_information.fetch(:lng))
    assert_equal 45.827801, company_information.fetch(:lat)
  end
end
