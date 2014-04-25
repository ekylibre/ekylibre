module Ekylibre
  module Access

    class << self 

      def reference_file
        Rails.root.join("config", "rights.yml")
      end

      def list
        LIST
      end
      
      def reversed_list
        REVERSED_LIST
      end
      
    end

    LIST = YAML.load_file(reference_file).with_indifferent_access.freeze
    
    REVERSED_LIST = LIST.inject({}) do |hash, pair|
      for action, details in pair.second
        for controller_action in details["actions"] || []
          hash[controller_action] ||= []
          hash[controller_action] << "#{action}-#{pair.first}"
        end
      end
      hash
    end.with_indifferent_access.freeze

  end
end
