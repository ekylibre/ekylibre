module Nomen
  class Reference
    attr_reader :set, :property, :foreign_nomenclature

    def initialize(set, property, foreign_nomenclature, type = :key)
      @set = set
      @type = type
      @property = property
      @foreign_nomenclature = foreign_nomenclature
      raise "Invalid nomenclature: #{@foreign_nomenclature.inspect}" unless @foreign_nomenclature.is_a?(Nomenclature)
    end

    def nomenclature
      @property.nomenclature
    end
  end
end
