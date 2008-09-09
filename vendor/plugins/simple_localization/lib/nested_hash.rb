module ArkanisDevelopment #:nodoc:
  module SimpleLocalization #:nodoc:
    
    # A NestedHash is an extended Hash to make handling of nested hash
    # structures easier. It adds a quick way to access and set keys of nested
    # hashes as well as recursive merge! and dup methods to merge or duplicate
    # structures.
    # 
    #   nh = NestedHash.from {:a => 1, :b => {:x => 9}}
    #   nh = NestedHash[:a => 1, :b => {:x => 9}]
    #   
    #   nh[:a]          # => 1
    #   nh[:b, :x]      # => 9
    #   nh[:b, :y] = 88
    #   nh              # => {:a => 1, :b => {:x => 9, :y => 88}}
    #   nh.merge! {:c => 2, :b => {:z => 'end'}
    #   nh              # => {:a => 1, :b => {:x => 9, :y => 88, :z => 'end'}, :c => 2}
    # 
    class NestedHash < Hash
      
      # Creates a new NestedHash object out of an ordinary hash (or
      # anything that is based on the class Hash).
      def self.from(hash)
        return nil unless hash.kind_of?(Hash)
        return hash if hash.kind_of?(self)
        new_nested_hash = self.new
        hash.each do |key, value|
          new_nested_hash[key] = value
        end
        new_nested_hash
      end
      
      # Gets a key out of the hash. To make access to keys of nested hashes
      # easier you can specify multiple keys, one per level.
      # 
      #   h = NestedHash[:a => 1, :b => {:x => 10, :y => 'test'}]
      #   h[:a]         # => 1
      #   h[:b, :x]     # => 10
      #   h[:b, :y]     # => 'test'
      #   h[:b, :dummy] #=> nil
      # 
      # Please note that ordinary hashes inside the hierarchical hash are not
      # altered. If you access them they will be returned as ordinary hashes.
      def [](*keys)
        if keys.length <= 1
          super
        else
          keys.inject(self) do |memo, key|
            memo[key] if memo and memo.kind_of?(Hash)
          end || (self.default_proc ? self.default_proc.call : nil) || self.default
        end
      end
      
      # Sets a key to the specified value. To make access to keys of nested
      # hashes easier you can specify multiple keys, one per level. If the
      # specified series of keys (the nested hashes inside) does not exist the
      # necessary hashes inside this NestedHash will be created automatically.
      # 
      #   h = HierarchicalHash[:a => 1, :b => {:x => 10, :y => 'test'}]
      #   h[:a] = 2
      #   h[:b, :x] = 20
      #   h[:b, :y] = 'next test'
      # 
      #   h[:dummy, :next] # => nil
      #   h[:dummy, :next] = 'auto create of nested hashes'
      #   h[:dummy, :next] # => 'auto create of nested hashes'
      # 
      def []=(*args)
        if args.length <= 2
          super
        else
          value = args.pop
          last_key = args.pop
          keys = args
          
          target_hash = keys.inject(self) do |memo, key|
            begin memo[key] rescue nil end || memo[key] = {}
          end
          
          target_hash[last_key] = value
          value
        end
      end
      
      # Merges the hash <code>other_hash</code> into this nested hash.
      # 
      # Please note that this method modifies this nested hash directly
      # and does not work on a copy. Hash inside these two objects are
      # converted to NestedHash objects during the merge process.
      # 
      # Based on "Hash recursive merge in Ruby" by Rex Chung:
      # http://www.rexchung.com/2007/02/01/hash-recursive-merge-in-ruby/
      # Added a bit more spice and flexibility...
      def merge!(other_hash)
        super(other_hash) do |key, old_val, new_val|
          if old_val.kind_of?(Hash) then self.class.from(old_val).merge!(new_val) else new_val end
        end
      end
      
      # Duplicates this NeastedHash and (recursive) all hashes within it.
      # 
      # Please note that all hashes within this NeastedHash are converted to
      # NeastedHash objects.
      def dup
        new_dup = super
        new_dup.each do |key, value|
          new_dup[key] = self.class.from(value).dup if value.kind_of?(Hash)
        end
      end
      
    end
    
  end
end
