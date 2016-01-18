module StateMachine
  class State
    def human_name(*_args)
      class_name = @machine.owner_class.name.underscore
      "state_machines.#{class_name}.states.#{@name}".t(default: ["models.#{class_name}.state_machine.states.#{@name}".to_sym, "models.#{class_name}.states.#{@name}".to_sym, @name.to_s.humanize])
    end
    alias localize human_name
    alias l localize
  end
end
