module Phytosanitary
  # Represents a group of risk levels.
  class Group
    @groups = []

    class << self
      def find_or_initialize(data)
        existing = find(data['group'])
        existing.tap    { |group| group && group.add_data(data) } ||
          new(data).tap { |group| @groups << group              }
      end

      def serialize_risks(list)
        list.split(', ').map(&:to_sym)
      end

      def find(number)
        @groups.find { |group| group.number == number.to_s.to_sym }
      end
      alias [] find
    end

    attr_reader :code, :number, :labels, :risk_codes

    def initialize(data)
      @code       = data['code']
      @number     = data['group'].to_sym
      @labels     = [data['label_fr']]
      @risk_codes = self.class.serialize_risks(data['risks'])
    end

    def add_data(data)
      @labels << data['label_fr']
      @risk_codes += self.class.serialize_risks(data['risks'])
    end

    def unknown?
      false
    end

    Unknown = Struct.new('UnknownGroup', :code, :number, :labels, :risk_codes) do
      def unknown?
        true
      end
    end
                    .new(nil, nil, [], [])
  end
end
