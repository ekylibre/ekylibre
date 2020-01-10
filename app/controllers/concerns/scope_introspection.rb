module ScopeIntrospection
  extend ActiveSupport::Concern

  included do
    class << self
      prepend KlassMethods
    end
  end

  class Scope < Struct.new(:name, :arity)
  end

  module KlassMethods
    attr_accessor :scopes

    def simple_scopes
      (scopes || []).select { |x| x.arity.zero? }
    end

    def complex_scopes
      (scopes || []).reject { |x| x.arity.zero? }
    end

    # Permits to consider something and something_id like the same
    def scope(name, body, &block)
      self.scopes ||= []
      self.scopes << Scope.new(name.to_sym, body.arity)

      super(name, body, &block)
    end
  end

end