# Represents a Response in DB.
class CallResponse < CallMessage
  belongs_to :request, class_name: 'CallRequest'
  delegate :method, :ip, :url, to: :request

  # Create a CallResponse from an ActionResponse
  def self.create_from_response!(response, request)
    create!(
      nature: :outgoing, # Because we come from a controller here.
      status: response.status,
      headers: response.headers,
      body: response.body,
      format: response.content_type,
      request: request
    )
  end

  def self.create_from_net_response!(response, request)
    create!(
      nature: :incoming, # Because we are receiving an answer.
      status: response.code,
      headers: response.to_hash,
      body: response.body,
      format: response.content_type,
      request: request
    )
  end
end
