module Clients
  module Mistral
    class NerGroq
      include AiHelper

      BASE_URL = 'https://api.groq.com/openai/v1/chat/completions'.freeze
      PROMPT_LIMIT = 25_000

      #  or mixtral-8x7b-32768
      def initialize(model = "llama-3.3-70b-versatile")
        @api_key = Identifier.find_by_nature('groq_api_key')&.value&.strip
        @content_to_send = { model: model, response_format: { type: 'json_object' }, messages: [{ role: 'system', content: nil }, { role: 'user', content: nil }] }
      end

      def extract_metadata(data, model_nature = nil)

        return { error: "missing groq_api_key in services" } if @api_key.blank?

        return { error: "missing data" } unless data.present?

        return { error: "missing model_nature" } unless model_nature.present?

        return { error: "data parameter is too long : #{data.size.to_s} characters instead of #{PROMPT_LIMIT} max" } if data.size > PROMPT_LIMIT

        # set instructions
        instructions = item_ai_instruction(model_nature)
        instructions << item_ai_output_schema(model_nature) if item_ai_output_schema(model_nature)
        @content_to_send[:messages][0][:content] = instructions
        @content_to_send[:messages][1][:content] = data
        # call Mistral API
        # call = RestClient.post BASE_URL, @content_to_send.to_json, headers
        call = RestClient::Request.execute(method: :post, url: BASE_URL, timeout: nil, payload: @content_to_send.to_json, headers: headers)
        response = JSON.parse(call.body).deep_symbolize_keys
        # get content only
        json_response = response[:choices][0][:message][:content]
        JSON.parse(json_response).deep_symbolize_keys
      rescue RestClient::ExceptionWithResponse => err
        { error: err }
      end

      def headers
        { content_type: 'application/json', accept: 'application/json', authorization: "Bearer #{@api_key}" }
      end

    end
  end
end
