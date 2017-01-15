module Ekylibre
  module View
    class Addon
      cattr_reader :list

      class << self
        # Backward compat
        alias view_addons list

        def add(partial_path, to: nil, for_action: nil)
          @list = [] if @list.nil?

          addon = {}
          addon[to] ||= {}
          addon[to][for_action] = partial_path
          @list << addon
        end

        def find(options)
          return unless options[:context]

          addons = []
          search_path = "#{options[:controller]}##{options[:action]}"
          # Backend is the default namespace
          search_path = 'backend/' + search_path unless search_path =~ %r{\/}

          @list.each do |addon|
            if addon.key?(options[:context]) && addon[options[:context]].key?(search_path)
              addons << addon[options[:context]][search_path]
            end
          end

          addons
        end
      end
    end
  end
end
