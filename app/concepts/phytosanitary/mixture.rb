module Phytosanitary
  # Represents a group of risk levels.
  class Mixture
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

    Incomplete = Struct.new('IncompleteMixture', :code, :label, :groups, :allowed) do
      def between?(first, other)
        [first, other].any?(&:unknown?)
      end
    end.new(nil, nil, [], nil)
  end
end
