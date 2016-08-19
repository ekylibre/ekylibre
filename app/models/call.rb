# Class representing an API Call, executed or not.
class Call < ActiveRecord::Base
  has_many :messages, class_name: 'CallMessage'

  # Sync
  def execute_now
    # Instantiate a ActionCaller object with itself as parameter
    # to execute the api call.
    @response = caller.new(self).send(method.to_sym, *args)

    yield(self) if block_given?
  end

  # ASync
  def execute
    # TODO: implement.
    raise NotImplementedError
  end

  def caller
    source.constantize
  end

  def success(code = nil)
    yield(@response) if state_is?(:success) && (!code || state_code_is?(code))
  end

  def error(code = nil)
    yield(@response) if state_is?(:error) && (!code || state_code_is?(code))
  end

  def redirect(code = nil)
    yield(@response) if state_is?(:redirect) && (!code || state_code_is?(code))
  end

  def on(code)
    yield(@response) if !code || state_code_is?(code)
  end

  private

  def state_is?(state)
    @response.state.to_s.split('_').first == state.to_s
  end

  def state_code_is?(state)
    @response.state.to_s.split('_')[1..-1].join('_') == state.to_s
  end
end
