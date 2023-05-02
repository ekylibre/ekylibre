module Ekylibre
  module Record
    class RecordNotUpdateable < ActiveRecord::RecordNotSaved
    end

    class RecordNotDestroyable < ActiveRecord::RecordNotSaved
    end

    class RecordNotCreateable < ActiveRecord::RecordNotSaved
    end

    class RecordInvalid < ActiveRecord::RecordNotSaved
    end

    Scope = Struct.new(:name, :arity) { }

    def self.human_name(model)
      ::I18n.t("activerecord.models.#{model}")
    end

  end
end
