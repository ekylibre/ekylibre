class CallResponse < CallMessage
  belongs_to :request, class_name: 'CallRequest'
  delegate :method, :ip, :url, :format, to: :request

  # Create a CallResponse from an ActionResponse
  def self.create_from_response!(response, request)
    create!(
      nature: :outgoing, # Because we come from a controller here.
      status: response.status,
      headers: response.headers,
      body: response.body,
      request: request
    )
  end
end
