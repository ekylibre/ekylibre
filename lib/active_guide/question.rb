module ActiveGuide

  class Question < Item

    def initialize(group, name, options = {})
      super group, name, options
    end

  end

end
