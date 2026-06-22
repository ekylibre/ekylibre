module Admin
  # Inspecte l'etat Bundler en memoire pour exposer la version Ekylibre et la liste
  # des plugins charges depuis Gemfile.local ou Gemfile.prod dont la source est un
  # depot github.com/ekylibre/<slug>.
  class PluginsInspector
    GITHUB_EKYLIBRE = %r{\Ahttps?://github\.com/ekylibre/([\w.-]+?)(?:\.git)?\z}.freeze
    ALLOWED_GEMFILES = %w[Gemfile.local Gemfile.prod].freeze

    Plugin = Struct.new(
      :name, :slug, :gemfile, :branch, :revision, :short_revision, :gem_version, :uri,
      keyword_init: true
    )
    Result = Struct.new(:ekylibre_version, :plugins, keyword_init: true)

    def call
      Result.new(
        ekylibre_version: ekylibre_version,
        plugins: collect_plugins
      )
    end

    private

      def ekylibre_version
        Ekylibre::VERSION.to_s.strip.presence
      rescue StandardError
        nil
      end

      def collect_plugins
        definition = Bundler.definition
        specs_by_name = definition.specs.each_with_object({}) { |s, h| h[s.name] = s }

        definition.dependencies.each_with_object([]) do |dep, list|
          slug = slug_from(dep)
          next unless slug
          next unless eligible_gemfile?(dep)

          list << build_plugin(dep, slug, specs_by_name[dep.name])
        end.sort_by { |p| p.slug.to_s.downcase }
      rescue StandardError => e
        Rails.logger.warn("[Admin::PluginsInspector] #{e.class}: #{e.message}") if defined?(Rails)
        []
      end

      def slug_from(dep)
        source = dep.source
        return nil unless source.is_a?(Bundler::Source::Git)

        uri = source.uri.to_s
        match = uri.match(GITHUB_EKYLIBRE)
        match && match[1]
      end

      def eligible_gemfile?(dep)
        path = dep.gemfile.to_s
        return false if path.empty?

        ALLOWED_GEMFILES.include?(File.basename(path))
      rescue StandardError
        false
      end

      def build_plugin(dep, slug, spec)
        source = dep.source
        revision = extract_revision(source, spec)
        Plugin.new(
          name: dep.name,
          slug: slug,
          gemfile: dep.gemfile.to_s,
          branch: source.branch.presence,
          revision: revision,
          short_revision: revision && revision[0, 7],
          gem_version: spec&.version&.to_s,
          uri: "https://github.com/ekylibre/#{slug}"
        )
      end

      def extract_revision(source, spec)
        rev = source.respond_to?(:revision) ? source.revision : nil
        rev ||= spec&.source.respond_to?(:revision) ? spec.source.revision : nil
        rev.to_s.presence
      end
  end
end
