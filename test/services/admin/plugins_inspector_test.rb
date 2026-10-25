require 'test_helper'

class Admin::PluginsInspectorTest < Ekylibre::Testing::ApplicationTestCase
  setup do
    @result = Admin::PluginsInspector.new.call
  end

  test 'exposes Ekylibre version' do
    assert_equal Ekylibre::VERSION.to_s.strip, @result.ekylibre_version
  end

  test 'returns Plugin structs sorted by slug' do
    slugs = @result.plugins.map(&:slug)
    assert_equal slugs.sort_by(&:downcase), slugs
  end

  test 'only includes gems sourced from github.com/ekylibre/*' do
    @result.plugins.each do |plugin|
      assert_match %r{\Ahttps://github\.com/ekylibre/}, plugin.uri,
                   "Plugin #{plugin.name} should be sourced from github.com/ekylibre but got #{plugin.uri}"
      assert plugin.slug.present?, "Plugin #{plugin.name} should expose a slug"
    end
  end

  test 'only includes gems declared in Gemfile.local or Gemfile.prod' do
    allowed = %w[Gemfile.local Gemfile.prod]
    @result.plugins.each do |plugin|
      basename = File.basename(plugin.gemfile.to_s)
      assert_includes allowed, basename,
                      "Plugin #{plugin.name} declared in #{basename}, expected one of #{allowed.inspect}"
    end
  end

  test 'excludes gems declared with path: (path source, not git)' do
    # Gemfile.local declares e.g. `idea`, `hajimari`, `ekylibre_ekyviti` with path:
    # → must not appear in the inspector output even though their slug is `ekylibre-*`.
    plugin_names = @result.plugins.map(&:name)
    %w[hajimari idea ekylibre_ekyviti agro_monitoring ekylibre_hve].each do |name|
      assert_not_includes plugin_names, name,
                          "Plugin #{name} is declared with path: and must not appear"
    end
  end

  test 'short_revision is the first 7 chars of revision when present' do
    @result.plugins.each do |plugin|
      next if plugin.revision.blank?

      assert_equal plugin.revision[0, 7], plugin.short_revision
    end
  end
end
