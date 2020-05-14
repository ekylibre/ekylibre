module Ekylibre
  module Testing
    module Concerns
      module MockUtils
        # Options should be of the form `method: retval`
        # @param [Object] object
        def stub_many(object, **options, &block)
          do_stub_many(object, options.to_a, &block)
        end

        private

          def do_stub_many(object, calls, &block)
            if calls.nil? || calls.empty?
              return block.call
            end

            (method, retval), *rest = calls
            object.stub method, retval do
              do_stub_many object, rest, &block
            end
          end
      end
    end
  end
end