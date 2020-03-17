module Nomen
  class Variety < Nomen::Record::Base
    TOPLEVEL_VARIETIES = %w[bioproduct immatter matter product product_group].freeze

    class << self
      def parent_variety(variety)
        v = find(variety)

        if v.nil?
          nil
        elsif (toplevel = toplevel_parent(v)).present?
          toplevel.name
        else
          v.name
        end
      end

      def toplevel_parent(variety)
        ancestors(variety).last
      end

      def ancestors(variety)
        if variety.parent.nil? || TOPLEVEL_VARIETIES.include?(variety.parent.name)
          []
        else
          [variety.parent, *ancestors(variety.parent)]
        end
      end
    end
  end
end
