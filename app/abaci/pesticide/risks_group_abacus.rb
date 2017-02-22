# The group of risks abacus
module Pesticide
  # See config/abaci/pesticide_risks_group.csv
  class RisksGroupAbacus < Ekylibre::Abaci
    def self.load
      super
      @data = @data.map { |row| Phytosanitary::Group.find_or_initialize(row) }
      true
    end

    def self.find_group_of(risk)
      risk = risk.code if risk.respond_to?(:code)
      @data.find { |group| group.risk_codes.include? risk.to_sym }
    end
  end
  RisksGroupAbacus.load
end
