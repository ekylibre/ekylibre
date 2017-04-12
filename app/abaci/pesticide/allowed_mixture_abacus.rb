# The allowed mixtures abacus
module Pesticide
  # See config/abaci/pesticide_allowed_mixture.csv
  class AllowedMixtureAbacus < Ekylibre::Abaci
    def self.load
      super
      @data = @data.map { |row| Phytosanitary::Mixture.new(row) }
      @data << Phytosanitary::Mixture::Incomplete
      true
    end

    def self.find_mixture(risk_group, other_group)
      @data.find { |mix| mix.between?(risk_group, other_group) }
    end

    def self.mixture_allowed?(risk_group, other_group)
      find_mixture(risk_group, other_group).allowed?
    end
  end
  AllowedMixtureAbacus.load
end
