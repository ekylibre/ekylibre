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
        @duration = Delay.new(element.attr('duration').to_s)
      end
      @tasks = element.xpath('xmlns:task').collect do |task|
        Task.new(self, task)
      end
    end

  end

end
