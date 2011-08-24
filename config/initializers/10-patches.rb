module Ekylibre
  module I18n

    module ContextualModelHelpers
      
      def tl(*args)
        args[0] = 'models.'+self.name.underscore+'.'+args[0].to_s
        ::I18n.translate(*args)
      end
      alias :tc :tl

      def tg(*args)
        args[0] = 'labels.'+args[0].to_s
        ::I18n.translate(*args)
      end

    end

    module ContextualModelInstanceHelpers
      
      def tl(*args)
        args[0] = 'models.'+self.class.name.underscore+'.'+args[0].to_s
        ::I18n.translate(*args)
      end
      alias :tc :tl

      def tg(*args)
        args[0] = 'labels.'+args[0].to_s
        ::I18n.translate(*args)
      end

    end

    module ContextualHelpers

      #       def tc(*args)
      #         args[0] = contextual_scope+'.'+args[0].to_s
      #         for i in 1..args.size
      #           args[i] = ::I18n.localize(args[i]) if args[i].is_a? Date
      #         end if args.size > 1
      #         ::I18n.translate(*args)
      #       end

      #       def tg(*args)
      #         args[0] = 'general.'+args[0].to_s
      #         ::I18n.translate(*args)
      #       end

      def tl(*args)
        args[0] = 'labels.'+args[0].to_s
        ::I18n.translate(*args)
      end
      alias :tc :tl
      alias :tg :tl
      
      private

      def contextual_scope
        app_dirs = '(helpers|controllers|views|models)'
        latest_app_file = caller.detect { |level| level =~ /.*\/app\/#{app_dirs}\/[^\.\.]/ }
        return 'eval' unless latest_app_file
        latest_app_file.split(/\/app\//)[1].split(/\./)[0].gsub('/','.').gsub(/(_controller$|_helper$|_observer$)/,'')
      end

    end

  end
end

ActionController::Base.send :extend, Ekylibre::I18n::ContextualHelpers
ActionController::Base.send :include, Ekylibre::I18n::ContextualHelpers
ActiveRecord::Base.send :extend, Ekylibre::I18n::ContextualModelHelpers
ActiveRecord::Base.send :include, Ekylibre::I18n::ContextualModelInstanceHelpers
ActionView::Base.send :include, Ekylibre::I18n::ContextualHelpers


module ::I18n

  def self.valid_locales
    return [:fra, :eng, :spa, :jpn, :arb] # , :spa, :jpn, :arb
    # FIXME Call to active_locales fails during migrate
    self.available_locales.select{|x| x.to_s.size == 3}
  end


  def self.active_locales
    @@active_locales ||= self.valid_locales
    @@active_locales
  end

  def self.active_locales=(array=[])
    @@active_locales ||= self.valid_locales
    @@active_locales = array unless array.empty?
  end

  def self.locale_label(locale=nil)
    locale ||= self.locale
    "#{locale} ("+self.locale_name+")"
  end

  def self.locale_name(locale=nil)
    locale ||= self.locale
    ::I18n.t("i18n.name")
  end

  def self.pretranslate(*args)
    res = translate(*args)
    if res.match(/translation\ missing|\(\(/)
      "((("+args[0].to_s.split(".")[-1].upper+")))"
    else
      "'"+res.gsub(/\'/,"''")+"'"
    end
  end

  def self.hardtranslate(*args)
    result = translate(*args)
    return (result.match(/translation\ missing|\(\(\(/) ? nil : result)
  end

end


if Rails.version.match(/^2\.3/)
  module ActiveRecord
    class Errors

      # allow a proc as a user defined message
      def add(attribute, message = nil, options = {})
        options[:message] = options.delete(:default) if options[:default].is_a?(Symbol)
        error, message = message, nil if message.is_a?(Error)
        raise ArgumentError.new("Symbol expected, #{message.inspect} received.") unless error or message.is_a?(Symbol) or options[:forced]

        @errors[attribute.to_s] ||= []
        @errors[attribute.to_s] << (error || Error.new(@base, attribute, message, options))
      end

      def add_to_base(msg, options = {})
        add(:base, msg, options)
      end
      
      def add_from_record(record)
        record.errors.each_error do |attribute, error|
          @errors[attribute.to_s] ||= []
          @errors[attribute.to_s] << error
        end
      end


      # Generate only full translated messages
      def generate_message(attribute, message = :invalid, options = {})
        message, options[:default] = options[:default], message if options[:default].is_a?(Symbol)

        defaults = @base.class.self_and_descendants_from_active_record.map do |klass|
          [ "models.#{klass.name.underscore}.attributes.#{attribute}.#{message}".to_sym, 
            "models.#{klass.name.underscore}.#{message}".to_sym ]
        end
        
        defaults << options.delete(:default)
        defaults = defaults.compact.flatten << "messages.#{message}".to_sym

        key = defaults.shift
        value = @base.respond_to?(attribute) ? @base.send(attribute) : nil

        options = { :default => defaults,
          :model => @base.class.human_name,
          :attribute => @base.class.human_attribute_name(attribute.to_s),
          :value => value,
          :scope => [:activerecord, :errors]
        }.merge(options)

        I18n.translate(key, options)
      end

      def full_messages(options = {})
        full_messages = []
        
        @errors.each_key do |attr|
          @errors[attr].each do |message|
            next unless message
            full_messages << message
          end
        end
        full_messages
      end 

    end
  end
else

  module ActiveModel
    class Errors

      #     # allow a proc as a user defined message
      #     def add(attribute, message = nil, options = {})
      #       message ||= :invalid
      #       raise options.inspect if options.frozen?
      
      #       message = generate_message(attribute, message, options) # if message.is_a?(Symbol)
      #       self[attribute] ||= []
      #       self[attribute] << message
      #     end
      

      def add(attribute, message = nil, options = {})
        message ||= :invalid
        
        if message.is_a?(Symbol)
          message = generate_message(attribute, message, options.except(*CALLBACKS_OPTIONS))
        elsif message.is_a?(Proc)
          message = message.call
        elsif !options.delete(:forced)
          raise ArgumentError.new("Symbol or Proc expected, #{message.inspect} received.")
        end
        
        self[attribute] << message
      end




      def add_to_base(message, options = {})
        add(:id, message, options)
      end

      def add_from_record(record)
        record.errors.each do |attribute, message|
          self[attribute] ||= []
          self[attribute] << message
        end
      end

      # Returns all the full error messages in an array.
      #
      #   class Company
      #     validates_presence_of :name, :address, :email
      #     validates_length_of :name, :in => 5..30
      #   end
      #
      #   company = Company.create(:address => '123 First St.')
      #   company.errors.full_messages # =>
      #     ["Name is too short (minimum is 5 characters)", "Name can't be blank", "Address can't be blank"]
      def full_messages(options = {})
        full_messages = []
        each do |attribute, messages|
          messages = Array.wrap(messages)
          full_messages += messages
        end
        full_messages
      end 

    end
  end

end


ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  msg = instance.error_message
  error_class = 'invalid'
  
  if html_tag =~ /<(input|textarea|select)[^>]+class=/
    class_attribute = html_tag =~ /class=['"]/
    html_tag.insert(class_attribute + 7, "#{error_class} ")
  elsif html_tag =~ /<(input|textarea|select)/
    first_whitespace = html_tag =~ /\s/
    html_tag[first_whitespace] = " class=\"#{error_class}\" "
  end
  
  html_tag
end
