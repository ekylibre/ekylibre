require 'test_helper'

class TransitionableTest < Ekylibre::Testing::ApplicationTestCase
  test 'creates transitionable class method' do
    class DummyTransition
      include Transitionable
    end

    assert DummyTransition.respond_to? :transitionable
  end

  test 'TransitionableShouldExtractOnlyTransitions' do
    class TransitionableShouldExtractOnlyTransitions

      module Transitions
        class TestTransition < Transitionable::Transition
          event :pouet
        end

        class ShouldNotBePicked
        end
      end

      include Transitionable
    end

    assert_equal 1, TransitionableShouldExtractOnlyTransitions.transitions.size
    assert TransitionableShouldExtractOnlyTransitions.transitions.values.first < Transitionable::Transition

    instance = TransitionableShouldExtractOnlyTransitions.new
    assert instance.respond_to?(:_get_transition)
    assert instance.respond_to?(:can_pouet?)
    assert instance.respond_to?(:pouet)
  end

  test 'predicate methods are generated for each Transition' do
    class TransitionableForTestPredicatesMethod
      module Transitions
        class Pouet < Transitionable::Transition
          event :pouet
        end

        class Tut < Transitionable::Transition
          event :tut
        end
      end

      include Transitionable
    end

    res = TransitionableForTestPredicatesMethod.new

    def res.state
      :pouet
    end

    assert %i[can_pouet? can_tut?].all? { |pred| res.methods.include? pred }

    pouet = TransitionableForTestPredicatesMethod::Transitions::Pouet
    pouet.send :define_method, :can_run? do
      true
    end
    tut = TransitionableForTestPredicatesMethod::Transitions::Tut
    tut.send :define_method, :can_run? do
      true
    end

    assert res.can_pouet?
    assert res.can_tut?
  end

  class TransitionTest < Ekylibre::Testing::ApplicationTestCase
    test 'from, event and to sets values on the class and return them when called without parameters' do
      class TransitionFromEventTo < Transitionable::Transition
        from :state1
        to :state2
        event :event_name
      end

      assert_equal [:state1], TransitionFromEventTo.from
      assert_equal :state2, TransitionFromEventTo.to
      assert_equal :event_name, TransitionFromEventTo.event
    end

    test 'can_run? returns true only if resource state is in the Transition initial states' do
      class Transition < Transitionable::Transition
        from :draft
      end

      assert_equal [:draft], Transition.from

      res = Object.new

      def res.state
        :draft
      end

      transition1 = Transition.new(res)
      assert transition1.can_run?

      res2 = Object.new

      def res2.state
        :pouet
      end

      transition2 = Transition.new(res2)
      assert_not transition2.can_run?
    end

    test 'run does no call transition if can_run? returns false' do
      transition = Transitionable::Transition.new Object.new

      def transition.can_run?
        false
      end

      def transition.transition
        raise StandardError.new("Should not be called")
      end

      assert_nothing_raised do
        transition.run # Should not call transition
      end
    end

    test "run calls transition if can_run returns true" do
      transition = Transitionable::Transition.new Object.new

      def transition.can_run?
        true
      end

      def transition.transition
        @called = true
      end

      transition.run
      assert transition.instance_variable_get(:@called)
    end

    test "run! raise a PreconditionFailedException if can_run? returns false" do
      transition = Transitionable::Transition.new Object.new

      def transition.can_run?
        false
      end

      assert_raise(Transitionable::PreconditionFailedError) { transition.run! }
    end

    test "the error field of transition is set when a transition fails and is nil when it suceeds" do
      t1 = Transitionable::Transition.new Object.new

      def t1.can_run?
        false
      end

      assert_not t1.run
      assert_instance_of Transitionable::PreconditionFailedError, t1.error

      t2 = Transitionable::Transition.new Object.new

      def t2.can_run?
        true
      end

      def t2.transition
        raise StandardError.new ""
      end

      assert_not t2.run
      assert_instance_of Transitionable::TransitionFailedError, t2.error

      t3 = Transitionable::Transition.new Object.new

      def t3.can_run?
        true
      end

      def t3.transition
        throw :abort
      end

      assert_not t3.run
      assert_instance_of Transitionable::TransitionAbortedError, t3.error

      t4 = Transitionable::Transition.new Object.new

      def t4.can_run?
        true
      end

      def t4.transition
        true
      end

      assert t4.run
      assert_nil t4.error
    end
  end

end