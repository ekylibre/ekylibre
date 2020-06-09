module FormObjects
  module Backend
    class Invitation
      class << self
        def with_defaults
          new(language: Preference['language'])
        end

        def reflect_on_association(association)
          if association == :role
            User.reflect_on_association(association)
          else
            nil
          end
        end
      end

      include Ekylibre::Model
      include Enumerize

      attr_accessor :first_name, :last_name, :language, :role_id, :email
      enumerize :language, in: I18n.available_locales, i18n_scope: ["nomenclatures.languages.items"]

      validates :first_name, :last_name, :language, :role_id, :email, presence: true

      validate do
        if email.present? && User.find_by(email: email).present?
          errors.add(:email, :taken)
        end
      end

      def attributes
        {
          first_name: first_name,
          last_name: last_name,
          language: language,
          role_id: role_id,
          email: email
        }
      end
    end
  end
end