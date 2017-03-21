module Ekylibre
  module View
    class Addon
      attr_accessor :condition, :partial, :options
      delegate :list, to: :class

      def initialize(partial, options = {})
        @partial = partial
        @options = options
      end

      def usable?(options = {})
        @condition.blank? || (@condition.present? && @condition.call(options))
      end

      class << self
        def list
          @list ||= {}.with_indifferent_access
        end

        # Backward compat
        alias view_addons list

        def add(context, partial_path, options = {})
          addon = new(partial_path, options)
          if options[:to]
            addon.condition = ->(options) { options[:controller] + '#' + options[:action] == options[:to] }
          end
          list[context] ||= []
          list[context] << addon
        end

        # Render all addons for a given context
        def render(context, template, options = {})
          return nil unless list[context]
          html = ''.html_safe
          list[context].each do |addon|
            if addon.usable?(options.merge(controller: template.controller_path, action: template.action_name, template: template).merge(addon.options.slice(:to)))
              html << template.render(addon.partial, options)
            end
          end
          html
        end
      end
    end
  end
end
