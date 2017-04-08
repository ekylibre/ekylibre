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
      operation = @intervention.operations.create!(started_at: @intervention.started_at, stopped_at: @intervention.stopped_at, reference_name: '100')
      @steps.each(&:save!)
      @intervention.state = :done
      @intervention.save!
    end

    # Add a cast to the intervention
    def cast(type, name, *args)
      options = args.extract_options!
      object = args.shift || options[:object]
      cast = Cast.new(self, type, name, object, options)
      @casting[name] = cast
      @steps << cast
      cast
    end

    %i[target doer tool input output].each do |name|
      code = "def #{name}(name, *args)\n"
      code << "  cast(:#{name}, name, *args)\n"
      code << "end\n"
      class_eval code
    end
  end
end
