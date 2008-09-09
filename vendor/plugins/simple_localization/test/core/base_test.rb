require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class BaseTest < Test::Unit::TestCase
  
  # TODO: find a proper way to test individual features in isolation and together
  
  # Doesn't work any longer because of the FeatureManager handling this stuff
  # now and this screws up this chaos...
  def test_preload_features
    #assert_kind_of Array, ArkanisDevelopment::SimpleLocalization::PRELOAD_FEATURES
    #loaded_features = simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => []
    #assert_equal ArkanisDevelopment::SimpleLocalization::PRELOAD_FEATURES, loaded_features
    #assert_equal loaded_features, ArkanisDevelopment::SimpleLocalization::Language.loaded_features
  end
  
end
