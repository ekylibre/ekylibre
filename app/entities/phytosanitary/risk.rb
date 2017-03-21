module Phytosanitary
  # Represent a risks
  class Risk
    attr_reader :code
    attr_reader :group

    def initialize(risk_level)
      @code  = risk_level.to_s
      @group = Pesticide::RisksGroupAbacus.find_group_of(@code) || Group[5]
    end

    def self.risks_of(variant)
      return [Unknown] unless maaid = variant.france_maaid
      risks = Pesticide::Agent.find(maaid).risks
      risks.map { |risk| new(risk) }
    end

    Unknown = Struct.new(:code, :group)
                    .new(nil, Phytosanitary::Group::Unknown)
  end
end
