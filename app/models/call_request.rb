# Represents a Request in DB.
class CallRequest < CallMessage
  has_many :responses, class_name: 'CallResponse'

  def self.create_from_request!(request)
    create!(
      nature: :incoming, # Because we are in one of our own controllers here.
      headers: request.headers,
      body: request.body,
      ip: request.ip,
      url: request.original_url,
      format: request.format,
      method: request.method,
      ssl: request.ssl?
    )
  end

  def self.create_from_net_request!(http, request, format)
    create!(
      nature: :outgoing, # We are hitting up someone.
      headers: request.to_hash,
      body: request.body,
      url: http.address + request.path,
      format: format,
      method: request.method,
      ssl: http.use_ssl?
    )
  end

  def last_response
    responses.order(:created_at).last
  end
end
