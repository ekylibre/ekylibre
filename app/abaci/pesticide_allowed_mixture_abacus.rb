# See config/abaci/pesticide_allowed_mixture.csv
class PesticideAllowedMixtureAbacus < Ekylibre::Abaci
  def self.load
    super
    @data = @data.map { |row| PesticideAllowedMixture.new(row) }
    true
  end

  def self.mixture_allowed?(risk_group, other_group)
    @data.find { |mix| mix.between?(risk_group, other_group) }
         .allowed?
  end
end

# Represents a group of risk levels.
class PesticideAllowedMixture
  attr_reader :code, :label, :groups, :allowed
  alias allowed? allowed

  def initialize(data)
    @code    = data['code'].to_sym
    @label   = data['label_fr']
    @groups  = [data['first_group'].to_sym, data['second_group'].to_sym]
    @allowed = data['allowed'] == 'true'
  end

  def between?(first, other)
    first = first.number if first.respond_to?(:number)
    other = other.number if other.respond_to?(:number)

    groups = [first, other].map(&:to_s).map(&:to_sym)

    @groups.sort == groups.sort
  end
end

PesticideAllowedMixtureAbacus.load
