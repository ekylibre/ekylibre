module RedHillConsulting::CascadingStylesheets::ActionView::Helpers
  module AssetTagHelper
    def self.included(base)
      base.class_eval do
        alias_method_chain :expand_stylesheet_sources, :cascade
      end
    end

    def expand_stylesheet_sources_with_cascade(sources)
      if sources.include?(:defaults)
        sources = sources.dup
        sources.delete(:defaults)

        candidates = controller.class.controller_path.split("/").inject([nil, nil]) { |candidates, candidate| candidates << (candidates.last ? File.join(candidates.last, candidate) : candidate) }
        candidates[0] = "application"
        candidates[1] = RAILS_ENV
        candidates.insert(2, controller.active_layout) if controller.active_layout
        candidates << File.join(candidates.last, controller.action_name)

        candidates.each do |source|
          sources << source if File.exists?(File.join(ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR, source + '.css'))
        end
      end

      expand_stylesheet_sources_without_cascade(sources)
    end
  end
end
