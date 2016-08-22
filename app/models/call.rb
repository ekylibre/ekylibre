# Class representing an API Call, executed or not.
class Call < ActiveRecord::Base
  has_many :messages, class_name: 'CallMessage'

  # Sync
  def execute_now(&block)
    # Instantiate a ActionCaller object with itself as parameter
    # to execute the api call.
    @response = caller.new(self).send(method.to_sym, *args)

    instance_exec(self, &block) if block_given?
  end
  alias execute execute_now

  # ASync
  # Not called #execute for risk users wouldn't notice the difference with
  # #execute_now and would call this one instead.
  def execute_async(&block)
    Thread.new do
      execute_now(&block)
      @state = :waiting
      @response = caller.new(self).send(method.to_sym, *args)
      @state = :done

      instance_exec(self, &block) if block_given?
    end
  end

  def caller
    source.constantize
  end

  def success(code = nil)
    yield(@response) if state_is?(:success) && state_code_matches?(code)
  end

  def error(code = nil)
    yield(@response) if state_is?(:error) && state_code_matches?(code)
  end

  def redirect(code = nil)
    yield(@response) if state_is?(:redirect) && state_code_matches?(code)
  end

  def on(code)
    yield(@response) if state_code_matches?(code)
  end

  private

  # Returns true for a nil/false code.
  def state_code_matches?(code)
    !code || state_code_is?(code)
  end

  def state_is?(state)
    @response.state.to_s.split('_').first == state.to_s
  end

  # Returns false for a nil/false code.
  def state_code_is?(state)
    @response.state.to_s.split('_')[1..-1].join('_') == state.to_s
  end
end
