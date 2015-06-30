class Intervention
  class Recorder

    attr_reader :intervention

    def initialize(attributes = {})
      @attributes = attributes
      @casting = {}
      @steps = []
      @intervention = Intervention.create!(@attributes)
    end

    def write!
      operation = @intervention.operations.create!(started_at: @intervention.started_at, stopped_at: @intervention.stopped_at, reference_name: "100")
      @steps.each do |step|
        if step.is_a?(Intervention::Recorder::Cast)
          step.save!
        elsif step.is_a?(Intervention::Recorder::Task)
          step.perform!(operation)
        else
          raise "What #{step.inspect} step !!!"
        end
      end
      @intervention.state = :done
      @intervention.save!
    end

    # Add a cast to the intervention
    def cast(name, *args)
      options = args.extract_options!
      object = args.shift || options[:object]
      puts object.inspect.red
      cast = Cast.new(self, name, object, options)
      @casting[name] = cast
      @steps << cast
      return cast
    end

    def task(type, parameters = {}, options = {})
      if p = Procedo::Action::TYPES[type]
        p.keys.each do |x|
          raise "Missing parameter: #{x.inspect} for #{type}" unless parameters.has_key? x
        end
      else
        raise "Invalid action type: #{type}"
      end
      @steps << ::Intervention::Recorder::Task.new(self, type, parameters, options)
    end


    Procedo::Action::TYPES.each do |name, args|
      # Add a task
      code  = "def #{name}(" + args.keys.join(', ') + ", options = {})\n"
      code << "  task(:#{name}, {" + args.keys.map{ |k| "#{k}: #{k}" }.join(", ") + "}, options)\n"
      code << "end\n"
      class_eval code
    end

  end
end
