module Nomen
  class Variety < Nomen::Record::Base

    def self.parent_variety(variety)
      v = find(variety)
      return unless v
      return v.name unless v.parent
      until %w[bioproduct immatter matter product product_group].include? v.parent.name || v.parent.nil?
        parent = v.parent.name
        v = find(parent)
      end
      v.name
    end
  end
end
