module Onoma
  module Record
    class Base
      class << self
        def respond_to?(method_name, include_private = false)
          Onoma.find_or_initialize(name.tableize.sub(%r{\Aonoma/}, ''))
               .respond_to?(method_name, include_private) || super
        end
      end
    end
  end
end
