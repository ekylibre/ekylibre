# frozen_string_literal: true

module Printers
  class TemplateFileProvider
    DEFAULT_ROOT_PATH = Rails.root.join('config', 'locales')

    attr_reader :locale, :root_path

    def initialize(locale: I18n.locale.to_s, root_path: DEFAULT_ROOT_PATH)
      @locale = locale
      @root_path = root_path
    end

    def find_by_nature(nature)
      [*odt_paths(nature), *jasper_paths(nature)].detect(&:exist?)
    end

    def find_by_template(template)
      if template.nil?
        nil
      elsif template.managed?
        find_by_nature template.nature
      else
        template.source_path
      end
    end

    private

      def odt_paths(nature)
        [
          root_path.join(locale, 'reporting', "#{nature}.odt"),
          root_path.join('eng', 'reporting', "#{nature}.odt"),
          root_path.join('fra', 'reporting', "#{nature}.odt")
        ]
      end

      def jasper_paths(nature)
        [
          root_path.join("#{nature}.xml"),
          root_path.join("#{nature}.jrxml")
        ]
      end
  end
end