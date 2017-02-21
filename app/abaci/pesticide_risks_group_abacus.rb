# See config/abaci/pesticide_risks_group.csv
class PesticideRisksGroupAbacus < Ekylibre::Abaci
  def self.load
    super
    @data = @data.map { |row| PesticideRiskGroup.find_or_initialize(row) }
    true
  end

  def self.find_group_of(risk)
    risk = risk.code if risk.respond_to?(:code)
    @data.find { |group| group.risk_codes.include? risk.to_sym }
  end
end

# Represents a group of risk levels.
class PesticideRiskGroup
  @groups = []

  class << self
    def find_or_initialize(data)
      existing = @groups.find { |group| group.number == data['group'].to_sym }
      existing.tap    { |group| group && group.add_data(data) } ||
        new(data).tap { |group| @groups << group              }
    end

    def serialize_risks(list)
      list.split(', ').map(&:to_sym)
    end
  end

  attr_reader :code, :number, :labels, :risk_codes

  def initialize(data)
    @code       = data['code']
    @number     = data['group'].to_sym
    @labels     = [data['label_fr']]
    @risk_codes = self.class.serialize_risks(data['risks'])
  end

  def add_data(data)
    @labels << data['label_fr']
    @risk_codes += self.class.serialize_risks(data['risks'])
  end
end

PesticideRisksGroupAbacus.load
