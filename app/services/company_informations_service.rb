# frozen_string_literal: true

class CompanyInformationsService
  def self.call(*args)
    new(*args).call
  end

  def initialize(
    company_info_client: Clients::Insee::SireneClient.new(key: ENV['INSEE_SIRENE_API_KEY'], secret: ENV['INSEE_SIRENE_API_SECRET']),
    address_info_client: Clients::Gouv::AddressClient.new,
    siren:
  )
    @company_info_client = company_info_client
    @address_info_client = address_info_client
    @siren = siren
  end

  def call
    nic = siren_infos.dig(:uniteLegale, :periodesUniteLegale)&.first&.fetch(:nicSiegeUniteLegale)
    return {} unless nic

    @siret = siren + nic
    etablissement = siret_infos[:etablissement]
    return {} unless etablissement

    address_etablissement = etablissement[:adresseEtablissement]
    city = [address_etablissement[:codePostalEtablissement], address_etablissement[:libelleCommuneEtablissement]].join(' ')
    address = build_address(address_etablissement)
    full_address = [address, city].join(' ')
    coordinates = get_geolocation(full_address)

    {
      company_name: etablissement.dig(:uniteLegale, :denominationUniteLegale),
      address: address,
      city: city,
      company_creation_date: Date.parse(etablissement[:uniteLegale][:dateCreationUniteLegale]),
      activity_code: etablissement[:uniteLegale][:activitePrincipaleUniteLegale],
      vat_number: nil,
      lng: coordinates[0],
      lat: coordinates[1],
      siret_number: siret
    }
  end

  private

    attr_reader :siren, :siret, :company_info_client, :address_info_client

    def siren_infos
      company_info_client.get_siren(siren)
    rescue RestClient::Exception => e
      { uniteLegale: { periodesUniteLegale: [] } }
    end

    def siret_infos
      return {} unless siret

      company_info_client.get_siret(siret)
    rescue RestClient::Exception => e
      {}
    end

    def get_geolocation(address)
      response = address_info_client.get_address(address)
      return {} unless response.dig(:features, 0, :geometry, :coordinates)

      response[:features][0][:geometry][:coordinates]
    end

    def build_address(raw_address)
      address = []
      address << raw_address[:numeroVoieEtablissement]
      address << raw_address[:indiceRepetitionEtablissement]
      address << raw_address[:typeVoieEtablissement]
      address << raw_address[:libelleVoieEtablissement]
      address.compact.join(' ')
    end
end
