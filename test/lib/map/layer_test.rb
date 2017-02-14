require 'test_helper'

module Map
  class LayerTest < ActiveSupport::TestCase
    test 'should load layers' do
      path = fixture_file('map_layers.yml')
      assert path.exist?, "Map layers config file doesn't exist"

      Map::Layer.load path
      assert !Map::Layer.items.empty?, 'No Layers loaded'

      fixtures = YAML.load_file(path).deep_symbolize_keys

      # All providers are registered ?
      fixtures.each do |k, v|
        assert Map::Layer.providers.select { |p| p == k }.count == 1

        v[:variants] = { default: nil } unless v.key?(:variants)
        v[:variants].keys.uniq.each do |variant|
          layer = Map::Layer.find("#{k}.#{variant}")
          assert layer.present?
          assert layer.name == variant
          assert_not_nil layer.url
          assert_not_nil layer.label

          assert [true, false].include?(layer.enabled)
          assert [true, false].include?(layer.by_default)
          assert_not_nil layer.options[:attribution]
        end
      end
    end
  end
end
