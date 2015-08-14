module Nomen
  module Migration
    class Base
      def self.parse(file)
        f = File.open(file, 'rb')
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        root = document.root
        number = file.basename.to_s.split('_').first.to_i
        new(number, root['name'], root)
      end

      attr_reader :number, :name

      def initialize(number, name, element = nil)
        @number = number
        @name = name
        @actions = []
        if element
          element.children.each do |child|
            next unless child.is_a? Nokogiri::XML::Element
            @actions << "Nomen::Migration::Actions::#{child.name.underscore.classify}".constantize.new(child)
          end
        end
      end

      def each_action(&block)
        @actions.each(&block)
      end

      def inspect
        "#<#{self.class.name}:#{sprintf('%#x', object_id)} ##{number} #{name.inspect} (#{@actions.size} actions)>"
      end
    end
  end
end
