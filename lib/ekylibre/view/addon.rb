module Ekylibre
  module View
    class Addon
      attr_reader :view_addons

      class << self
        def add(partial_path, to: nil, for_action: nil)
          @view_addons = [] if @view_addons.nil?

          view_addon = {}
          view_addon[to] ||= {}
          view_addon[to][for_action] = partial_path
          @view_addons << view_addon
        end

        def find(options)
          return unless options[:context]

          addons = []
          search_path = "backend/#{options[:controller]}##{options[:action]}"

          @view_addons.each do |view_addon|
            addons << view_addon[options[:context]][search_path] if view_addon.key?(options[:context]) && view_addon[options[:context]].key?(search_path)
          end

          addons
        end
      end
    end
  end
end
