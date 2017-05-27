module Backend
  module Cells
    class LastEventsCellsController < Backend::Cells::BaseController
      list(model: :events) do |t|
        t.column :started_at
        t.column :description
      end

      def show; end
    end
  end
end
