class ExportJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(params, user)
    params = JSON.load(params)
    klass = Aggeratio[params['id']]
    aggregator = klass.new(params)
    format = params['format']
    user = User.find(user)
    name = params['template'].to_i

    unless template = DocumentTemplate.find_active_template(name)
      raise StandardError, "Can not find template for \#{name.inspect}"
    end

    filename = "#{klass.human_name}.#{format}"

    key = params['key'] || SecureRandom.hex(2)
    # Export and send file
    begin
      # Export the file
      path = template.export(aggregator.to_xml, key, format)
      document_id = Document.find_by(key: key).id
      # Send a notification to user
      notification = user.notifications.build(valid_generation_notification_params(path, filename, document_id))
    rescue => error
      # When error create a notification with error message
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
      notification = user.notifications.build(error_generation_notification_params(filename, params['id'], error.message))
    end
    notification.save
  end
end

def error_generation_notification_params(_filename, id, error)
  {
    message: 'error_during_file_generation',
    level: :error,
    target_type: 'Document',
    target_url: backend_export_path(id),
    interpolations: {
      error_message: error
    }
  }
end

def valid_generation_notification_params(_path, _filename, document_id)
  {
    message: 'file_generated',
    level: :success,
    target_type: 'Document',
    target_url: backend_document_path(document_id),
    interpolations: {}
  }
end
