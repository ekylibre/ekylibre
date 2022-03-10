# frozen_string_literal: true

class WorkerGroupItem < ApplicationRecord

  belongs_to :worker_group, class_name: "WorkerGroup"
  belongs_to :worker, class_name: "Product"

end
