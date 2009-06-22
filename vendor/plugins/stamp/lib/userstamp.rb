module Stamp
  # Active Records will automatically record the user who created and/or updated a database objects
  # if fields of the names created_by/created_by are present.
  #
  # This module requires that your user object (which by default is <tt>User</tt> but can be changed
  # using the <tt>user_model_name</tt> method) contains an accessor called <tt>current_user</tt> and
  # is set with the instance of the currently logged in user (typically using a <tt>before_filter</tt> and the
  # session.
  #
  # The functionality can be turned off on a case by case basis by setting the <tt>record_userstamps</tt>
  # property of your ActiveRecord object to false.
  module Userstamp
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def self.extended(base)
        class << base
          alias_method_chain :create, :user
          alias_method_chain :update, :user
        end
      end

      # This method is an alias for the normal <tt>create</tt> method. This is where we set the <tt>created_by</tt>
      # and <tt>updated_by</tt> attributes. This only happens if the attributes exist for the model, the
      # <tt>record_userstamps</tt> attribute is true, and the user model has the <tt>current_user</tt> set.
      #
      # After we update those attributes we continue by running the normal <tt>create</tt> method where the object
      # is actually validated and saved.
      def create_with_user
        puts ">>>>> create_with_user"
        if record_userstamps and user_model.current_user != nil
          puts "ok!"
          write_attribute(:created_by, user_model.current_user.id.to_i) if respond_to?(:created_by) and self.created_by.nil?
          write_attribute(:updated_by, user_model.current_user.id.to_i) if respond_to?(:updated_by)
        end
        create_without_user
      end

      # This method is an alias for the normal <tt>update</tt> method. This is where we set the <tt>updated_by</tt>
      # attribute. This only happens if the attributes exist for the model, the <tt>record_userstamps</tt>
      # attribute is true, and the user model has the <tt>current_user</tt> set.
      #
      # After we update those attributes we continue by running the normal <tt>update</tt> method where the object
      # is actually validated and saved.
      def update_with_user
        puts ">>>>>>>>>> update_with_user"
        if record_userstamps and user_model.current_user != nil
          puts "ok"
          write_attribute(:updated_by, user_model.current_user.id.to_i) if respond_to?(:updated_by)
        end
        update_without_user
      end

    end

  end

end

module ActiveRecord
  class Base
    @@user_model_name = :users
    cattr_accessor :user_model_name

    @@record_userstamps = true
    cattr_accessor :record_userstamps

    def self.relates_to_user_in(model)
      self.user_model_name = model
    end

    def user_model
      Object.const_get(self.user_model_name.to_s.singularize.humanize)
    end
  end
end
