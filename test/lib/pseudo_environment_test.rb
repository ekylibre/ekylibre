require 'test_helper'

class PseudoEnvironmentTest < ActiveSupport::TestCase
  setup do
    @pseudo_env = PseudoEnvironment.new(self)
    @real_env = Rails.env

    # Tests will be pointless if we're pseudo-ing
    # from production to production.
    assert_not_equal :production, @real_env
  end

  test '#set_to(env) allows us to pretend we\'re in another env' do
    @pseudo_env.set_to(:production)
    assert Rails.env.production?
  end

  test '#unset brings us back to the real env' do
    @pseudo_env.set_to(:production)
    @pseudo_env.unset
    assert_equal @real_env, Rails.env
  end

  test '#set_to with block automatically unsets after execution' do
    @pseudo_env.set_to(:production) do
      assert Rails.env.production?
    end
    assert_equal @real_env, Rails.env
  end

  test '#inspect contains info about both environments' do
    @pseudo_env.set_to(:production)
    assert_match Regexp.new('production'),   @pseudo_env.inspect
    assert_match Regexp.new(@real_env.to_s), @pseudo_env.inspect
  end

  test 'doesn\'t impact other processes/threads' do
    @threads_done = {}
    Thread.abort_on_exception = true
    @prod_thread = Thread.new(self) do |tester|
      class ProcessInProd
        def execute(tester)
          PseudoEnvironment.new(self).set_to(:production)
          tester.assert Rails.env.production? # Not unset
          tester.thread_done(Thread.current)
          tester.wait_for_non_prod { Thread.pass } # Ensure development & unaware run w/ bad env set
        end
      end

      ProcessInProd.new.execute(tester)
    end

    @unaware_thread = Thread.new(self) do |tester|
      class UnawareProcess
        def execute(tester)
          tester.wait_for_prod { Thread.pass }    # Ensure bad env is set before running
          tester.assert_equal tester.real_env, Rails.env
          tester.assert_not Rails.env.production?
          tester.assert_not Rails.env.development?
          tester.thread_done(Thread.current)
        end
      end

      UnawareProcess.new.execute(tester)
    end

    @development_thread = Thread.new(self) do |tester|
      class ProcessInDevelopment
        def execute(tester)
          PseudoEnvironment.new(self).set_to(:development)
          tester.wait_for_prod { Thread.pass }    # Ensure bad env is set before running
          tester.assert Rails.env.development?
          tester.assert_not Rails.env.production?
          tester.thread_done(Thread.current)
        end
      end

      ProcessInDevelopment.new.execute(tester)
    end

    @prod_thread.join
    @unaware_thread.join
  end

  test 'can be matched with "normal" envs' do
    @pseudo_env.set_to(@real_env)
    assert_equal @real_env, Rails.env
  end

  attr_reader :real_env

  def thread_done(thread)
    @threads_done[thread] = true
  end

  def wait_for_prod
    yield until @threads_done[@prod_thread]
  end

  def wait_for_non_prod
    yield until @threads_done[@unaware_thread] && @threads_done[@development_thread]
  end

  teardown do
    @pseudo_env.unset
  end
end
