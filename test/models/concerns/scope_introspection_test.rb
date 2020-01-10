require 'test_helper'

class ScopeInstrospectionTest < ActiveSupport::TestCase
  class Introspectable
    include ScopeIntrospection

    class << self
      attr_accessor :scope_called
    end

    def self.scope(*_args)
      self.scope_called = true
    end

    scope :blah, -> { 42 }
  end

  setup do
    @obj = Introspectable.new
  end

  test 'a call to scope should be registered' do
    assert_equal 1, Introspectable.simple_scopes.length
    assert Introspectable.scope_called
  end
end