# frozen_string_literal: true

require 'test_helper'

class SireneSearchServiceTest < ActiveSupport::TestCase
  ETABLISSEMENT = {
    siret: '12345678900012',
    siren: '123456789',
    uniteLegale: {
      denominationUniteLegale: 'ACME SARL',
      activitePrincipaleUniteLegale: '01.11Z',
      dateCreationUniteLegale: '2010-05-01'
    },
    adresseEtablissement: {
      numeroVoieEtablissement: '10',
      typeVoieEtablissement: 'RUE',
      libelleVoieEtablissement: 'DE LA PAIX',
      codePostalEtablissement: '44000',
      libelleCommuneEtablissement: 'NANTES'
    }
  }.freeze

  class FakeClient
    attr_reader :calls

    def initialize(establishment: ETABLISSEMENT)
      @establishment = establishment
      @calls = []
    end

    def get_siret(siret)
      @calls << [:get_siret, siret]
      { etablissement: @establishment }
    end

    def get_establishments_of_legal_unit(siren, number: nil)
      @calls << [:get_establishments_of_legal_unit, siren, number]
      { etablissements: [@establishment] }
    end

    def search_establishments(query, number: nil)
      @calls << [:search_establishments, query, number]
      { etablissements: [@establishment] }
    end
  end

  test 'maps an establishment to a pre-fill candidate' do
    client = FakeClient.new
    candidate = SireneSearchService.call('ACME', client: client).first

    assert_equal 'ACME SARL', candidate[:name]
    assert_equal '12345678900012', candidate[:siret]
    assert_equal '44000 NANTES', candidate[:city]
    assert_equal '10 RUE DE LA PAIX', candidate[:address]
    assert_equal '01.11Z', candidate[:activity_code]
    assert_equal '2010-05-01', candidate[:born_on]
    assert_equal Clients::Insee::FrenchVat.from_siren('123456789'), candidate[:vat_number]
    assert_equal 'ACME SARL — 44000 NANTES', candidate[:label]
  end

  test 'flags the administrative state (active vs closed)' do
    # ETABLISSEMENT has no etat field → treated as active
    assert_equal true, SireneSearchService.call('acme', client: FakeClient.new).first[:active]

    closed = FakeClient.new(establishment: ETABLISSEMENT.merge(etatAdministratifEtablissement: 'F'))
    assert_equal false, SireneSearchService.call('acme', client: closed).first[:active]
  end

  test 'a 14-digit query hits the SIRET endpoint' do
    client = FakeClient.new
    SireneSearchService.call('123 456 789 00012', client: client)
    assert_equal :get_siret, client.calls.first.first
  end

  test 'a 9-digit query lists the legal unit establishments' do
    client = FakeClient.new
    SireneSearchService.call('123456789', client: client)
    assert_equal :get_establishments_of_legal_unit, client.calls.first.first
  end

  test 'a free-text query searches by name' do
    client = FakeClient.new
    SireneSearchService.call('boulangerie', client: client)
    assert_equal :search_establishments, client.calls.first.first
  end

  test 'a blank query does not call the API' do
    client = FakeClient.new
    assert_empty SireneSearchService.call('  ', client: client)
    assert_empty client.calls
  end
end
