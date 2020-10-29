module Backend
  module TransitionExceptionRenderingHelper
    def render_transition_error(error)
      description = render_nested_error(error)

      with_i18n_scope :transitions, replace: true do
        stl :error_message_html,
            **interpolation_options(error),
            description: description.html_safe
      end
    end

    private

      def render_nested_error(error)
        if error.is_a? ::Transitionable::TransitionError
          handle_transition_error(error)
        elsif error.is_a? ActiveRecord::RecordInvalid
          content_tag(:ul) do
            error.record.errors.full_messages.map do |message|
              content_tag(:li, message)
            end.sum
          end
        else
          error.message
        end
      end

      def interpolation_options(error)
        {
          resource_name: error.resource.number,
          previous_state: translate_state(error.resource, error.transition.attribute, error.resource.old_record.state),
          state: translate_state(error.resource, error.transition.attribute, error.transition.class.to)
        }
      end

      def translate_state(resource, attribute, state)
        resource.class.send(attribute).human_value_name(state)
      end

      def handle_transition_error(error)
        if error.is_a? ::Transitionable::ExplainedTransitionError
          inner_message = render_nested_error(error.cause)

          with_translation_scope(error) do
            stl error.explanation, { **error.options, message: inner_message }
          end
        else
          with_i18n_scope :transitions, :errors, replace: true do
            stl error.class.name.underscore, **interpolation_options(error), **translated_interpolations(error)
          end
        end
      end

      def translated_interpolations(error)
        with_i18n_scope *i18n_scope_for(error.resource, error.transition), :interpolations, replace: true do
          error.interpolations.map { |key, value| [key, stl(value)] }.to_h
        end
      end

      def with_translation_scope(error, &block)
        with_i18n_scope *i18n_scope_for(error.resource, error.transition), :errors, replace: true, &block
      end

      def i18n_scope_for(resource, transition)
        [:transitions, resource.class.name.underscore, transition.class.event]
      end
  end
end