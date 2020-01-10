module Phytosanitary
  # Represent a risks
  class Risk
    attr_reader :code
    attr_reader :group

    def self.get(risk_level)
      return Unknown if risk_level.blank?
      new(risk_level)
    end

    def initialize(risk_level)
      @code  = risk_level.to_s
      @group = Pesticide::RisksGroupAbacus.find_group_of(@code)
    end

    def self.risks_of(variant)
      return [Unknown] unless maaid = variant&.france_maaid
      risks = Pesticide::Agent.find(maaid).risks
      risks.map { |risk| get(risk) }
    end

    Unknown = Struct.new('UnknownRisk', :code, :group)
                    .new(nil, Phytosanitary::Group::Unknown)
  end
end
