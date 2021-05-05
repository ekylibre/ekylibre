# app/serializers/hash_serializer.rb
# see https://github.com/heartcombo/simple_form/wiki/Nested-inputs-for-key-value-hash-attributes
class HashSerializer
  def self.dump(hash)
    hash
  end

  def self.load(hash)
    (hash || {}).with_indifferent_access
  end
end
