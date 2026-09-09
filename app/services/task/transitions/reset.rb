# frozen_string_literal: true

class Task
  module Transitions
    class Reset < Transitionable::Transition
      event :reset
      from :doing, :done
      to :todo

      def transition
        resource.state = :todo
        resource.save!
      end
    end
  end
end
