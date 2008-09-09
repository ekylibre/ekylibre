require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.dirname(__FILE__) + '/../lang_section_proxy_helper'

class LangSectionProxyTest < Test::Unit::TestCase
  
  include ArkanisDevelopment::SimpleLocalization
  
  def test_normal_proxy
    data = [1, 2, 3]
    LanguageMock.current_lang_data = data
    proxy = CachedLangSectionProxy.new :lang_class => LanguageMock
    
    assert_equal data, proxy
  end
  
  def test_proxy_hash_with_transformation_and_caching
    orignial_data = {:a => 'first', :b => 'second', :c => 'third'}
    lang_data = {:a => 'erster', :c => 'dritter'}
    LanguageMock.current_lang_data = lang_data
    block_execution_count = 0
    
    proxy = CachedLangSectionProxy.new :lang_class => LanguageMock, :orginal_receiver => orignial_data do |localized, original|
      block_execution_count += 1
      original.merge localized
    end
    
    assert_equal 0, block_execution_count
    proxy.size
    assert_equal 1, block_execution_count
    20.times { proxy.size }
    assert_equal 1, block_execution_count
    
    merged_data = orignial_data.merge lang_data
    assert_equal merged_data, proxy
  end
  
  def test_proxy_caching_with_multiple_languages
    orignial_data = {:a => 'first', :b => 'second', :c => 'third'}
    lang_a_data, lang_b_data, lang_c_data = {:a => 'lang1 first'}, {:b => 'lang2 second'}, {:c => 'lang3 third'}
    
    LanguageMock.data = {
      :a => lang_a_data,
      :b => lang_b_data,
      :c => lang_c_data
    }
    LanguageMock.current_language = :a
    block_execution_count = 0
    
    proxy = CachedLangSectionProxy.new :lang_class => LanguageMock, :orginal_receiver => orignial_data do |localized, original|
      block_execution_count += 1
      original.merge localized
    end
    
    assert_equal 0, block_execution_count
    proxy.size
    assert_equal 1, block_execution_count
    20.times { proxy.size }
    assert_equal 1, block_execution_count
    merged_lang_a_data = orignial_data.merge lang_a_data
    assert_equal merged_lang_a_data, proxy
    
    LanguageMock.current_language = :b
    assert_equal 1, block_execution_count
    proxy.size
    assert_equal 2, block_execution_count
    20.times { proxy.size }
    assert_equal 2, block_execution_count
    merged_lang_b_data = orignial_data.merge lang_b_data
    assert_equal merged_lang_b_data, proxy
    
    LanguageMock.current_language = :c
    assert_equal 2, block_execution_count
    proxy.size
    assert_equal 3, block_execution_count
    20.times { proxy.size }
    assert_equal 3, block_execution_count
    merged_lang_c_data = orignial_data.merge lang_c_data
    assert_equal merged_lang_c_data, proxy
    
    # The receivers for all languages are cached now so the block_execution_count
    # should not rise from now one.
    LanguageMock.current_language = :a
    assert_equal 3, block_execution_count
    proxy.size
    assert_equal 3, block_execution_count
    20.times { proxy.size }
    assert_equal 3, block_execution_count
    merged_lang_a_data = orignial_data.merge lang_a_data
    assert_equal merged_lang_a_data, proxy
  end
  
end
