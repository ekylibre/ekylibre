require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Define a mock for the feature manager
class FeatureManagerMock < ArkanisDevelopment::SimpleLocalization::FeatureManager
  
  def read_available_features
    [:feature_a, :feature_b, :feature_c, :feature_d]
  end
  
  def reset
    self.send :initialize
  end
  
end


class FeatureManagerTest < Test::Unit::TestCase
  
  def setup
    @manager = FeatureManagerMock.instance
    @manager.reset
    @feature_list = [:feature_a, :feature_b, :feature_c, :feature_d]
  end
  
  def test_available_features
    assert_equal @feature_list, @manager.all_features
  end
  
  def test_plugin_init_features
    assert_equal [], @manager.plugin_init_features
    @manager.preload :feature_a, :feature_b
    assert_equal [:feature_a, :feature_b], @manager.plugin_init_features
    @manager.freeze_plugin_init_features!
    assert_equal [:feature_a, :feature_b], @manager.plugin_init_features
  end
  
  def test_load_scenario
    @manager.disable :feature_a
    @manager.preload :feature_a, :feature_b
    assert_equal [:feature_b], @manager.plugin_init_features
    @manager.freeze_plugin_init_features!
    assert_equal [:feature_b], @manager.plugin_init_features
    @manager.load :feature_c, :feature_d
    assert_equal [:feature_c, :feature_d], @manager.localization_init_features
    assert_equal [:feature_b], @manager.unwanted_features
  end
  
end
