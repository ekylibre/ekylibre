module PanierLocal
  class Base < ActiveExchanger::Base
    def import_resource
      @import_resource ||= Import.find(options[:import_id])
    end
  end
end