module Lexicon
  module Concerns
    module Finalizable
      extend ActiveSupport::Concern

      included do
        class << self
          alias_method :_new, :new

          def new(*args, **options)
            e = _new(*args, **options)

            ObjectSpace.define_finalizer(e, e.method(:_finalize))

            e
          end
        end
      end

      private

        def finalize
          raise StandardError, "Finalizer is not implemented in #{self.class.name}"
        end

        def _finalize(_id)
          m = method(:finalize)

          if !m.nil?
            finalize
          end
        rescue StandardError => e
          puts "Exception in finalizer: #{e.message}\n" + e.backtrace.join("\n")
        end
    end
  end
end