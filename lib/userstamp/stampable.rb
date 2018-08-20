module Userstamp
  # Extends the stamping functionality of ActiveRecord by automatically recording the model
  # responsible for creating, updating, and deleting the current object. See the Stamper
  # and Userstamp modules for further documentation on how the entire process works.
  module Stampable
    def self.included(base) #:nodoc:
      super

      base.extend(ClassMethods)
      base.class_eval do
        include InstanceMethods

        # Should ActiveRecord record userstamps? Defaults to true.
        class_attribute :record_userstamp
        self.record_userstamp = true

        # Which class is responsible for stamping? Defaults to :user.
        class_attribute :stamper_class_name

        # What column should be used for the creator stamp?
        # Defaults to :creator_id when compatibility mode is off
        # Defaults to :created_by when compatibility mode is on
        class_attribute :creator_attribute

        # What column should be used for the updater stamp?
        # Defaults to :updater_id when compatibility mode is off
        # Defaults to :updated_by when compatibility mode is on
        class_attribute :updater_attribute

        # What column should be used for the deleter stamp?
        # Defaults to :deleter_id when compatibility mode is off
        # Defaults to :deleted_by when compatibility mode is on
        class_attribute :deleter_attribute
      end
    end

    module ClassMethods
      # This method is automatically called on for all classes that inherit from
      # ActiveRecord, but if you need to customize how the plug-in functions, this is the
      # method to use. Here's an example:
      #
      #   class Post < ActiveRecord::Base
      #     stampable :stamper_class_name => :person,
      #               :creator_attribute => :create_user,
      #               :updater_attribute => :update_user,
      #               :deleter_attribute => :delete_user
      #   end
      #
      # The method will automatically setup all the associations, and create <tt>before_save</tt>
      # and <tt>before_create</tt> filters for doing the stamping.
      def stampable(options = {})
        defaults = {
          stamper_class_name: :user,
          creator_attribute: :creator_id,
          updater_attribute: :updater_id,
          deleter_attribute: :deleter_id
        }.merge(options)

        self.stamper_class_name = defaults[:stamper_class_name].to_sym
        self.creator_attribute  = defaults[:creator_attribute].to_sym
        self.updater_attribute  = defaults[:updater_attribute].to_sym
        self.deleter_attribute  = defaults[:deleter_attribute].to_sym

        class_eval do
          klass = stamper_class_name.to_s.singularize.camelize
          belongs_to(:creator, class_name: klass, foreign_key: creator_attribute)
          belongs_to(:updater, class_name: klass, foreign_key: updater_attribute)

          before_save :set_updater_attribute
          before_create :set_creator_attribute

          # if self.respond_to?(:columns_definition) && self.columns_definition[:deleter_id]
          #   belongs_to(:deleter, , class_name: klass, foreign_key: deleter_attribute)
          #   before_destroy :set_deleter_attribute
          # end
        end
      end

      # Temporarily allows you to turn stamping off. For example:
      #
      #   Post.without_stamps do
      #     post = Post.find(params[:id])
      #     post.update_attributes(params[:post])
      #     post.save
      #   end
      def without_stamps
        original_value = record_userstamp
        self.record_userstamp = false
        yield
        self.record_userstamp = original_value
      end

      def stamper_class #:nodoc:
        stamper_class_name.to_s.capitalize.constantize
      rescue
        nil
      end
    end

    module InstanceMethods #:nodoc:
      private

      def has_stamper?
        !self.class.stamper_class.nil? && !self.class.stamper_class.stamper.nil?
      rescue
        false
      end

      def set_creator_attribute
        return unless record_userstamp
        if respond_to?(creator_attribute.to_sym) && has_stamper?
          send("#{creator_attribute}=".to_sym, self.class.stamper_class.stamper)
        end
      end

      def set_updater_attribute
        return unless record_userstamp
        if respond_to?(updater_attribute.to_sym) && has_stamper?
          send("#{updater_attribute}=".to_sym, self.class.stamper_class.stamper)
        end
      end

      def set_deleter_attribute
        return unless record_userstamp
        if respond_to?(deleter_attribute.to_sym) && has_stamper?
          send("#{deleter_attribute}=".to_sym, self.class.stamper_class.stamper)
          save
        end
      end
      # end private
    end
  end
end
