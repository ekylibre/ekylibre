module ActiveGuide
  class Result

    attr_reader :group, :name, :type
    
    def initialize(group, name, type = :numeric)
      @group = group
      @name = name
      @type = type
    end

  end
end
