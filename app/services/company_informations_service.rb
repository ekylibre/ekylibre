# frozen_string_literal: true

class CompanyInformationsService
  def self.call(*args)
    new(*args).call
  end

  def initialize(
    company_info_client: Clients::Insee::SireneClient.new(key: ENV['INSEE_SIRENE_API_KEY'], secret: ENV['INSEE_SIRENE_API_SECRET']),
    address_info_client: Clients::Gouv::AddressClient.new,
    siren: nil,
    siret: nil,
    name: nil,
    postal_code: nil
  )
    @company_info_client = company_info_client
    @address_info_client = address_info_client
    @siren = siren
    @siret = siret
    @name = name
    @postal_code = postal_code
  end

  def call
    if @siren.present?
      nic = siren_infos.dig(:uniteLegale, :periodesUniteLegale)&.first&.fetch(:nicSiegeUniteLegale)
      return {} unless nic

      @siret = siren + nic
      etablissement = siret_infos[:etablissement]
    elsif @siret.present?
      etablissement = siret_infos[:etablissement]
    elsif @name.present?
      etablissement = company_infos
      @siret = etablissement[:siret]
    end

    puts etablissement.inspect.green

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
      lng: (coordinates.present? ? coordinates[0] : nil),
      lat: (coordinates.present? ? coordinates[1] : nil),
      siret_number: siret
    }
  end

  private

    attr_reader :siren, :siret, :company_info_client, :address_info_client, :name, :postal_code

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

    def company_infos
      return {} unless name

      begin
        a = company_info_client.get_legal_unit_by_name(name)
      rescue RestClient::Exception => e
        nil
      end

      begin
        b = company_info_client.get_enterprise_by_name(name)
      rescue RestClient::Exception => e
        nil
      end

      begin
        c = company_info_client.get_enterprise_by_name_and_postal_code(name, postal_code) if postal_code.present?
      rescue RestClient::Exception => e
        nil
      end

      # case SIRET found from name
      if c.present?
        c[:etablissements]&.first
      elsif b.present?
        b[:etablissements]&.first
      # case SIREN found from name
      elsif a.present?
        eta_siren = a[:unitesLegales]&.first&.fetch(:siren)
        eta_nic = a[:unitesLegales]&.first&.fetch(:periodesUniteLegale)&.first&.fetch(:nicSiegeUniteLegale)
        eta_siret = eta_siren + eta_nic
        ca = company_info_client.get_siret(eta_siret)
        ca[:etablissement]
      else
        nil
      end
    end

    def get_geolocation(address)
      response = address_info_client.get_address(address)
      return {} unless response.dig(:features, 0, :geometry, :coordinates)

      response[:features][0][:geometry][:coordinates]
    rescue RestClient::Exception => e
      {}
    end

    def build_address(raw_address)
      address = []
      address << raw_address[:complementAdresseEtablissement]
      address << raw_address[:numeroVoieEtablissement]
      address << raw_address[:indiceRepetitionEtablissement]
      address << raw_address[:typeVoieEtablissement]
      address << raw_address[:libelleVoieEtablissement]
      address.compact.join(' ')
    end
end
