require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class NestedHashTest < Test::Unit::TestCase
  
  def setup
    @default_hash = {:a => 1, :b => {:x => 10, :y => 'test', :z => {:e => 9}}, :x => 'end'}
  end
  
  def test_creation_from_other_hash
    original_hash = {:a => 1, :b => 'x'}
    hash_out_of_other_hash = ArkanisDevelopment::SimpleLocalization::NestedHash.from original_hash
    hash_directly_created = ArkanisDevelopment::SimpleLocalization::NestedHash[:a => 1, :b => 'x']
    [hash_out_of_other_hash, hash_directly_created].each do |hash_to_test|
      assert_not_nil hash_to_test
      assert_kind_of ArkanisDevelopment::SimpleLocalization::NestedHash, hash_to_test
      assert_equal original_hash.size, hash_to_test.size
    end
  end
  
  def test_access_operator
    hash = ArkanisDevelopment::SimpleLocalization::NestedHash.from @default_hash
    assert_kind_of ArkanisDevelopment::SimpleLocalization::NestedHash, hash
    assert_equal @default_hash[:a], hash[:a]
    assert_equal @default_hash[:b][:x], hash[:b, :x]
    assert_kind_of Numeric, hash[:a]
    assert_kind_of String, hash[:b, :y]
    assert_kind_of Hash, hash[:b]
    assert_kind_of Hash, hash[:b, :z]
  end
  
  def test_default_value
    hash = ArkanisDevelopment::SimpleLocalization::NestedHash.from @default_hash
    assert_nil hash[:none]
    assert_nil hash[:a, :none]
    assert_nil hash[:b, :x, :none]
    
    default_value = 'DEFAULT'
    hash.default = default_value
    assert_equal default_value, hash[:none]
    assert_equal default_value, hash[:a, :none]
    assert_equal default_value, hash[:b, :x, :none]
  end
  
  def test_default_proc
    hash = setup_nested_hash_with_default_exception
    assert_raise RuntimeError do hash[:not_existing_entry] end
    assert_raise RuntimeError do hash[:not, :existing_entry] end
  end
  
  def test_set_operator
    hash = ArkanisDevelopment::SimpleLocalization::NestedHash.from @default_hash
    assert_equal @default_hash[:a], hash[:a]
    return_val = (hash[:a] = 2)
    assert_equal 2, hash[:a]
    assert_equal 2, return_val
    return_val = (hash[:b, :x] = 20)
    assert_equal 20, hash[:b, :x]
    assert_equal 20, return_val
  end
  
  def test_auto_create_of_set_operator
    hash = ArkanisDevelopment::SimpleLocalization::NestedHash.from @default_hash
    hash[:c] = 99
    assert_equal 99, hash[:c]
    hash[:d, :a, :a] = 100
    assert_equal 100, hash[:d, :a, :a]
  end
  
  def test_auto_create_of_set_operator_with_default_exception
    hash = setup_nested_hash_with_default_exception
    assert_nothing_raised do hash[:a, :b] = 200 end
    assert_kind_of Hash, hash[:a]
    assert_equal 200, hash[:a, :b]
    assert_nothing_raised do hash[:a, :bh, :c] = 300 end
    assert_kind_of Hash, hash[:a]
    assert_kind_of Hash, hash[:a, :bh]
    assert_equal 300, hash[:a, :bh, :c]
  end
  
  def test_merge!
    hash_to_merge = {:a => 2, :b => {:y => 'merged_test', :z => {:f => 90}}}
    hash_to_test = ArkanisDevelopment::SimpleLocalization::NestedHash.from @default_hash
    hash_to_test.merge! hash_to_merge
    assert_equal hash_to_merge[:a], hash_to_test[:a]
    assert_equal @default_hash[:b][:x], hash_to_test[:b, :x]
    assert_equal hash_to_merge[:b][:y], hash_to_test[:b, :y]
    assert_equal @default_hash[:b][:z][:e], hash_to_test[:b, :z, :e]
    assert_equal hash_to_merge[:b][:z][:f], hash_to_test[:b, :z, :f]
    assert_kind_of ArkanisDevelopment::SimpleLocalization::NestedHash, hash_to_test[:b, :z]
    assert_equal @default_hash[:x], hash_to_test[:x]
  end
  
  def test_dup
    hash = ArkanisDevelopment::SimpleLocalization::NestedHash.from @default_hash
    new_hash = hash.dup
    
    assert_not_equal new_hash.object_id, hash.object_id
    assert_equal new_hash[:a].object_id, hash[:a].object_id
    assert_not_equal new_hash[:b].object_id, hash[:b].object_id
    assert_equal new_hash[:b, :y].object_id, hash[:b, :y].object_id
    assert_not_equal new_hash[:b, :z].object_id, hash[:b, :z].object_id
    
    new_hash[:b, :z] = nil
    assert_nil new_hash[:b, :z]
    assert_not_nil hash[:b, :z]
  end
  
  protected
  
  def setup_nested_hash_with_default_exception
    ArkanisDevelopment::SimpleLocalization::NestedHash.new do |hash, key|
      raise RuntimeError, "Entry #{key.inspect} could not be found in hash #{hash.inspect}"
    end
  end
  
end
