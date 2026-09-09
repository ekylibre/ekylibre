# frozen_string_literal: true

class Task
  module Transitions
    class Finish < Transitionable::Transition
      event :finish
      from :todo, :doing
      to :done

      def transition
        resource.state = :done
        resource.save!
      end
    end
  end
end
