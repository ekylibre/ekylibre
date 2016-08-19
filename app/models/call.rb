# Class representing an API Call, executed or not.
class Call < ActiveRecord::Base
  has_many :messages, class_name: 'CallMessage'

  # Sync
  def execute_now
    # Instantiate a ActionCaller object with itself as parameter
    # to execute the api call.
    caller.new(self).send(method.to_sym, *args)
  end

  # ASync
  def execute
    # TODO: implement.
    raise NotImplementedError
  end

  def caller
    source.constantize
  end
end
