module Procedo

  class Operation
    attr_reader :id, :procedure, :tasks, :duration

    def initialize(procedure, element)
      @procedure = procedure
      if element.has_attribute?('id')
        @id = element.attr('id').to_i
      else
        raise MissingAttribute.new("Each operation must have an id attribute (which must be a decimal integer). In: #{@procedure.signature}.")
      end
      if element.has_attribute?('duration')
        expr = element.attr('duration').to_s.strip.split(/\s+/)
        @duration = expr.first.to_d.send(expr.second)
      end
      @tasks = element.xpath('xmlns:task').collect do |task|
        Task.new(self, task)
      end
    end


    def no_duration?
      @duration.nil?
    end
    
    def human_name
      "Operation ##{self.id}"
    end


  end

end
