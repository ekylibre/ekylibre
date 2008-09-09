require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.dirname(__FILE__) + '/../lang_section_proxy_helper'

class LangSectionProxyTest < Test::Unit::TestCase
  
  include ArkanisDevelopment::SimpleLocalization
  
  def test_proxy_string
    data = 'test'
    LanguageMock.current_lang_data = data
    proxy = LangSectionProxy.new :lang_class => LanguageMock
    assert_equal data.to_s, proxy.to_s
    assert_equal data, proxy
  end
  
  def test_proxy_array
    data = [1, 2, 3, 4, 5]
    LanguageMock.current_lang_data = data
    proxy = LangSectionProxy.new :lang_class => LanguageMock
    assert_equal data, proxy
    
    # The receivers object_id doesn't change because it's always the same
    # section of the language file and thus the same object in memory.
    assert_equal proxy.receiver.object_id, proxy.receiver.object_id
  end
  
  def test_proxy_hash
    data = {:a => 1, :b => 'text'}
    LanguageMock.current_lang_data = data
    proxy = LangSectionProxy.new :lang_class => LanguageMock
    assert_equal data, proxy
    
    # The receivers object_id doesn't change because it's a section of the language file.
    assert_equal proxy.receiver.object_id, proxy.receiver.object_id
  end
  
  def test_proxy_transformation
    data = [1, 2, 3]
    additional_data = [4, 5]
    LanguageMock.current_lang_data = data
    proxy = LangSectionProxy.new :lang_class => LanguageMock do |localized_data|
      localized_data + additional_data
    end
    
    assert_equal data + additional_data, proxy
  end
  
  def test_proxy_hash_with_transformation_and_no_caching
    orignial_data = {:a => 'first', :b => 'second', :c => 'third'}
    lang_data = {:a => 'erster', :c => 'dritter'}
    LanguageMock.current_lang_data = lang_data
    proxy = LangSectionProxy.new :lang_class => LanguageMock, :orginal_receiver => orignial_data do |localized, original|
      localized.reverse_merge original
    end
    
    merged_data = lang_data.reverse_merge orignial_data
    assert_equal merged_data, proxy
    
    # The LangSectionProxy class does not cache the receivers and thus two
    # calls result in two different (combined on each call) reciever objects.
    assert_not_equal proxy.receiver.object_id, proxy.receiver.object_id
  end
  
  def test_receiver_fallback
    LanguageMock.loaded = false
    LanguageMock.current_lang_data = 'not loaded yet'
    
    proxy = LangSectionProxy.new :lang_class => LanguageMock, :orginal_receiver => 'fallback'
    assert_equal 'fallback'.to_s, proxy.to_s
    assert_equal 'fallback', proxy
  end
  
end
