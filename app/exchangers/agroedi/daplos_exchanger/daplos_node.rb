module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class DaplosNode
      attr_reader :daplos, :parent, :children

      def initialize(parent, daplos)
        @daplos = daplos
        @parent = parent
        @children = {}
      end

      def unregister(from: parent)
        collection = (from.children[daplos_nature] ||= [])
        collection.delete(self)
      end

      def register(to: parent)
        @parent = to
        collection = (to.children[daplos_nature] ||= [])
        collection << self unless collection.include? self
      end

      def daplos_nature
        class_name = self.class.name.split('::').last
        name = (self.class.node_name || class_name).to_s
        name.underscore.pluralize.to_sym
      end

      def daplos_line
        daplos.to_s.gsub(/\s+/, ' ')
      end

      def inspect
        pretty_class = self.class.name.split('::').last
        "#{pretty_class}#<parent: #{parent.inspect} line: #{daplos_line.inspect}>"
      end

      class << self
        def node_name(name_if_writing = nil)
          return @node_name if name_if_writing.blank?

          @node_name = name_if_writing
        end

        def daplos_parent(parent_name)
          alias_method parent_name.to_sym, :parent
        end
      end
    end
  end
end
