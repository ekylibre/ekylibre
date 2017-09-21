# Small wrapper around the Rails.env variable that allows
# us to pretend we're in another env than the actual one.
class PseudoEnvironment < SimpleDelegator
  attr_reader :real_env, :current_env, :scope, :explicit_label

  def initialize(caller, explicit_label = true)
    @scope = caller
    @real_env = Rails.env
    @explicit_label = explicit_label
    super(@real_env)
  end

  def set_to(new_env)
    unset unless new_env.nil?
    @current_env = new_env
    Rails.instance_variable_set(:@_env, self)

    define_env_response(real_env, false)
    define_env_response(current_env, true)
    return new_env unless block_given?

    yield

    unset
  end
  alias set set_to

  def unset
    set_to(nil)
    return if current_env.blank?
    class << self
      env_test = :"#{Rails.env.to_s}?"
      undef_method env_test if defined?(env_test)
    end
    Rails.instance_variable_set(:@_env, real_env)
    real_env
  end

  def inspect
    return to_s unless explicit_label
    "#{self} (actual: #{real_env})"
  end

  def to_s
    main_env = current_env || real_env
    main_env.to_s
  end

  delegate :===, to: :current_env

  private

  def define_env_response(env, response)
    return if env.blank?
    define_singleton_method(:"#{env}?") do
      in_caller = binding.callers.find { |binding| binding.eval('self') == scope }
      return response if in_caller
      real_env.send("#{env}?")
    end
  end
end
