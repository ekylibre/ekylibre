module Ekylibre
  module Record #:nodoc:
    module Bookkeep
      extend ActiveSupport::Concern

      ACTIONS = %i[create update destroy].freeze

      def accounted?
        !accounted_at.nil?
      end

      module ClassMethods
        def bookkeep(options_or_klass = nil, options = {}, &block)
          klass = nil
          if block
            options = options_or_klass || options
            raise ArgumentError.new("Wrong number of arguments (#{block.arity} for 1)") unless block.arity == 1
          else
            klass = options_or_klass
            implicit_bookkeeper_name = "#{self.name}Bookkeeper"
            if klass.nil? || const_defined?(implicit_bookkeeper_name)
              klass ||= const_get(implicit_bookkeeper_name)
            end
            raise ArgumentError.new('Provided class does not respond to #call method') unless klass.nil? || klass.instance_methods.include?(:call)
          end

          raise ArgumentError.new('Neither bookkeeping class nor block given') unless klass || block

          configuration = { on: Ekylibre::Record::Bookkeep::ACTIONS, column: :accounted_at, method_name: __method__ }
          configuration.update(options) if options.is_a?(Hash)
          configuration[:column] = configuration[:column].to_s
          method_name = configuration[:method_name].to_s
          core_method_name ||= "_#{method_name}_#{Ekylibre::Record::Bookkeep::Base.next_id}"

          unless columns_definition[configuration[:column]]
            Rails.logger.fatal "#{configuration[:column]} is needed for #{name}::bookkeep"
            # raise StandardError, "#{configuration[:column]} is needed for #{self.name}::bookkeep"
          end

          define_method method_name do |action = :create, draft = nil|
            draft = ::Preference[:bookkeep_in_draft] if draft.nil?
            unsuppress do
              send(core_method_name, Ekylibre::Record::Bookkeep::Base.new(self, action, draft))
            end
            # `update_columns` et non `where(id:).update_all` : depuis Rails 6,
            # `update_all` incrémente lui-même `lock_version` quand le modèle a
            # le verrouillage optimiste. L'écriture de `accounted_at` rendait
            # alors périmée l'instance en mémoire — celle-là même qui vient de
            # déclencher le callback — et toute sauvegarde ultérieure levait
            # `StaleObjectError`. `update_columns` écrit la colonne sans toucher
            # au verrou et garde l'attribut à jour côté Ruby.
            #
            # Sur `after_destroy` la ligne n'existe plus : l'`update_all` d'hier
            # n'y touchait aucune ligne, tandis qu'`update_columns` refuserait
            # d'écrire sur un enregistrement détruit.
            update_columns(configuration[:column] => Time.zone.now) unless destroyed?
          end

          configuration[:on] = [configuration[:on]].flatten
          Ekylibre::Record::Bookkeep::ACTIONS.each do |action|
            next unless configuration[:on].include? action

            send("after_#{action}") do
              if ::Preference[:bookkeep_automatically]
                send(method_name, action, ::Preference[:bookkeep_in_draft])
              end
              true
            end
          end

          if block
            send(:define_method, core_method_name, &block)
          else
            send(:define_method, core_method_name) { |*args|
              klass.new(*args).call
            }
          end
        end
      end
    end
  end
end

require_relative 'bookkeep/entry_recorder'
require_relative 'bookkeep/base'
