module Ekylibre
  class Snippet
    @snippets = {}.with_indifferent_access

    class << self
      def add(name, path, options = {})
        place = options.delete(:place) || :side
        @snippets[place] ||= []
        @snippets[place] << new(name, path, options)
      end

      def at(place)
        @snippets[place] || []
      end
    end

    attr_reader :name, :path

    def initialize(name, path, options = {})
      @name = name
      @path = path
      @options = options
    end

    def options
      @options.dup
    end
  end
end
