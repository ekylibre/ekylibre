class Intervention
  class Recorder

    class Cast

      attr_reader :object

      def initialize(recorder, name, object = nil, options = {})
        @recorder = recorder
        @name = name
        @object = object
        @variant = options.slice(:variant)
        @options = {}
      end

      def save!
        if @variant.present?
          @recorder.intervention.add_cast!(@options.merge(reference_name: @name, variant: @object))
        else
          @recorder.intervention.add_cast!(@options.merge(reference_name: @name, actor: @object))
        end
      end

    end

  end
end
