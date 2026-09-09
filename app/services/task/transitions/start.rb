# frozen_string_literal: true

class Task
  module Transitions
    class Start < Transitionable::Transition
      event :start
      from :todo, :done
      to :doing

      def transition
        resource.state = :doing
        resource.save!
      end
    end
  end
end
