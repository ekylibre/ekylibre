json.id resource.id.to_s
json.cashRegisterId resource.cash_id
json.sequence resource.number
json.openDate resource.started_at.to_time.to_i
json.closeDate resource.stopped_at.to_time.to_i if resource.stopped_at
json.openCash resource.noticed_start_amount.to_f
json.closeCash resource.noticed_stop_amount.to_f
json.expectedCash resource.expected_stop_amount.to_f
