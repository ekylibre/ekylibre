module Unrollable
  # Small all-purpose tools.
  module Toolbelt
    class << self
      def first_if_alone(enum)
        enum.size == 1 ? enum.first : enum
      end

      def if_there(obj)
        obj.present? ? obj : nil
      end

      def true?(object)
        object.to_s == 'true'
      end

      def symbolized(array)
        array.map { |element| element.is_a?(Hash) ? element.symbolize_keys : element }
      end

      def deep_compact(object)
        return nil if object.blank?
        case object
        when Array          then object.map { |o| deep_compact(o) }.compact
        when Hash           then object.map { |k, v| [k, deep_compact(v)] }.to_h
        when Symbol, String then object
        else raise "What a parameter? #{object.inspect}"
        end
      end
    end

    protected

    def first_if_alone(enum)
      Unrollable::Toolbelt.first_if_alone(enum)
    end

    def if_there(obj)
      Unrollable::Toolbelt.if_there(obj)
    end

    def true?(object)
      Unrollable::Toolbelt.true?(object)
    end

    def symbolized(array)
      Unrollable::Toolbelt.symbolized(array)
    end

    def deep_compact(object)
      Unrollable::Toolbelt.deep_compact(object)
    end
  end
end
