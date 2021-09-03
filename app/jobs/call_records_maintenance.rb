class CallRecordsMaintenance < ApplicationJob
  queue_as :default

  def perform_on_tenant
    calls = Call.where('created_at < ?', Date.today - 1.month)
    CallMessage.where(call_id: calls.pluck(:id)).delete_all
    calls.delete_all
  end
end
