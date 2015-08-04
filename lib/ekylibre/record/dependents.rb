module Ekylibre::Record  #:nodoc:
  module Dependents
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      # Look for all has_one, has_many and has_and_belongs_to_many reflections
      def has_dependents?
        refs = self.class.reflect_on_all_associations.select { |r| r.macro.to_s.match(/^has_/) }
        return false unless refs.size > 0
        method_name = 'has_' + refs.collect { |r| r.name.to_s }.sort.join('_or_') + '?'
        unless self.respond_to?(method_name)
          code = ''
          code << "def #{method_name}\n"
          code << '  return (' + refs.collect do |r|
            if r.macro.to_s == 'has_one'
              "self.#{r.name}"
            else
              "self.#{r.name}.first"
            end
          end.join(' || ') + ")\n"
          code << "end\n"
          class_eval(code)
        end
        send(method_name)
      end
    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Dependents)
