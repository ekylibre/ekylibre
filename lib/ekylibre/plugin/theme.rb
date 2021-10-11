# frozen_string_literal: true

module Ekylibre
  class Plugin
    class Theme
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def precompile_path
        "themes/#{name}/all.css"
      end
    end
  end
end
