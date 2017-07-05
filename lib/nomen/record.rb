module Nomen
  module Record
    class Base
      class << self
        def method_missing(*args, &block)
          Nomen.find_or_initialize(name.tableize.gsub(/\Anomen\//, '')).send(*args, &block)
        end

        def respond_to?(method_name)
          Nomen.find_or_initialize(name.tableize.gsub(/\Anomen\//, '')).respond_to?(method_name) || super
        end
      end
    end
  end
end
