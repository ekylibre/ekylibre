# frozen_string_literal: true

# Searches the INSEE Sirene directory and returns a small list of candidate
# companies ready to pre-fill an Entity. Accepts a SIRET (14 digits), a SIREN
# (9 digits) or a free-text name. Network failures degrade to an empty list —
# the form still works by hand.
class SireneSearchService
  NETWORK_ERRORS = CompanyInformationsService::NETWORK_ERRORS
  MAX_RESULTS = 20

  def self.call(query, client: nil)
    new(query, client: client).call
  end

  def initialize(query, client: nil)
    @raw = query.to_s.strip
    @client = client || Clients::Insee::SireneClient.new(api_key: ENV['INSEE_SIRENE_API_KEY'])
  end

  # @return [Array<Hash>] candidates
  def call
    return [] if @raw.blank?

    fetch_establishments.map { |establishment| candidate(establishment) }.compact
  rescue *NETWORK_ERRORS => e
    Rails.logger.warn("SireneSearchService failed (#{e.class}): #{e.message}")
    []
  end

  private

    def digits
      @raw.gsub(/[^0-9]/, '')
    end

    def fetch_establishments
      case digits.length
      when 14
        # A single establishment Hash — wrap in a literal array (Array(hash)
        # would explode it into [key, value] pairs).
        [@client.get_siret(digits)[:etablissement]].compact
      when 9
        Array(@client.get_establishments_of_legal_unit(digits, number: MAX_RESULTS)[:etablissements])
      else
        Array(@client.search_establishments("raisonSociale:#{@raw}", number: MAX_RESULTS)[:etablissements])
      end
    end

    def candidate(establishment)
      return nil if establishment.blank?

      legal_unit = establishment[:uniteLegale] || {}
      raw_address = establishment[:adresseEtablissement] || {}
      siret = establishment[:siret]
      siren = establishment[:siren] || siret&.slice(0, 9)
      name = company_name(legal_unit)
      address = build_address(raw_address)
      city = city_of(raw_address)

      {
        siret: siret,
        siren: siren,
        name: name,
        address_complement: raw_address[:complementAdresseEtablissement],
        address: address,
        city: city,
        activity_code: legal_unit[:activitePrincipaleUniteLegale],
        born_on: legal_unit[:dateCreationUniteLegale],
        vat_number: siren.present? ? Clients::Insee::FrenchVat.from_siren(siren) : nil,
        active: establishment_active?(establishment, legal_unit),
        label: [name, city].reject(&:blank?).join(' — ')
      }
    end

    # INSEE administrative state: 'A' active, 'F' closed. Check the establishment
    # (its current period), falling back to the legal unit; assume active when
    # unknown so a missing field never hides a company.
    def establishment_active?(establishment, legal_unit)
      etat = establishment[:etatAdministratifEtablissement] ||
             establishment.dig(:periodesEtablissement, 0, :etatAdministratifEtablissement) ||
             legal_unit[:etatAdministratifUniteLegale]
      etat.nil? || etat.to_s == 'A'
    end

    def company_name(legal_unit)
      legal_unit[:denominationUniteLegale].presence ||
        [legal_unit[:prenom1UniteLegale], legal_unit[:nomUniteLegale]].compact.join(' ').presence
    end

    def city_of(address)
      [address[:codePostalEtablissement], address[:libelleCommuneEtablissement]].compact.join(' ').strip
    end

    # The street line only (complement lives in address_complement so the two
    # can feed distinct address lines).
    def build_address(address)
      %i[numeroVoieEtablissement indiceRepetitionEtablissement
         typeVoieEtablissement libelleVoieEtablissement].map { |k| address[k] }.compact.join(' ').strip
    end
end
