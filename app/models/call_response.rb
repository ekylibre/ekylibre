class CallResponse < CallMessage
  belongs_to :request, class_name: 'CallMessage'
  delegate :method, :ip, :url, :format, to: :request

  def self.create_from_response!(response, request)
    create!(
      status: response.status,
      headers: response.headers,
      body: response.body,
      request: request
    )
  end
end
