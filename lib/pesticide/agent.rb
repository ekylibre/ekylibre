module Pesticide
  class Agent
    class << self
      def all
        unless @data
          source = Rails.root.join('config', 'specialities.yml')
          @data = if source.exist?
                    YAML.load_file(source).deep_symbolize_keys.stringify_keys
                  else
                    {}
                  end
        end
        @data
      end

      def find(id, _options = {})
        return nil unless all[id]
        @data[id] = new(all[id].merge(number: id)) unless all[id].is_a?(Pesticide::Agent)
        all[id]
      end
    end

    attr_reader :number, :risks, :usages

    def initialize(attributes = {})
      @number = attributes.delete(:number).to_s
      @risks = attributes.delete(:risks)
      @usages = if attributes[:usages]
                  attributes.delete(:usages).map do |u|
                    Pesticide::Usage.new(u)
                  end
                else
                  []
                end
      @attributes = attributes
    end
  end
end
