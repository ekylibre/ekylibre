# Small wrapper around the Rails.env variable that allows
# us to pretend we're in another env than the actual one.
#
# La feinte est enregistrée par thread : `Rails.env` est bien remplacé
# globalement — il n'y a qu'une variable pour tout le processus — mais les
# prédicats `production?`, `development?`… ne rendent la valeur feinte qu'aux
# threads qui l'ont demandée. Les autres continuent de voir l'environnement
# réel, ce que vérifie `test/lib/pseudo_environment_test.rb`.
#
# La version précédente identifiait l'appelant en remontant la pile avec
# `binding_of_caller`. Ruby 3.4 refuse de construire un `Binding` pour une
# trame créée par du code C — ce qui est le cas d'une méthode posée par
# `define_singleton_method` puis appelée à travers `SimpleDelegator` — et tout
# prédicat levait alors `RuntimeError: Cannot create Binding object for
# non-Ruby caller`.
class PseudoEnvironment < SimpleDelegator
  # Clé de l'environnement feint dans les variables du thread courant.
  REGISTRY_KEY = :pseudo_environment
  private_constant :REGISTRY_KEY

  attr_reader :real_env, :scope, :explicit_label

  def initialize(caller, explicit_label = true)
    @scope = caller
    @real_env = Rails.env
    @explicit_label = explicit_label
    super(@real_env)
  end

  # L'environnement feint du thread courant, s'il en a demandé un.
  def current_env
    Thread.current[REGISTRY_KEY]
  end

  def set_to(new_env)
    Thread.current[REGISTRY_KEY] = new_env.nil? ? nil : ActiveSupport::StringInquirer.new(new_env.to_s)
    Rails.instance_variable_set(:@_env, new_env.nil? ? real_env : self)
    return new_env unless block_given?

    begin
      yield
    ensure
      unset
    end
  end
  alias set set_to

  def unset
    Thread.current[REGISTRY_KEY] = nil
    Rails.instance_variable_set(:@_env, real_env)
    real_env
  end

  def inspect
    return to_s unless explicit_label

    "#{self} (actual: #{real_env})"
  end

  def to_s
    (current_env || real_env).to_s
  end

  def ==(other)
    to_s == other.to_s
  end

  def ===(other)
    (current_env || real_env) === other
  end

  # Les prédicats d'environnement (`production?`, `development?`, …) sont
  # résolus depuis la feinte du thread courant. Hors feinte, `SimpleDelegator`
  # les délègue à l'`ActiveSupport::StringInquirer` réel, dont le
  # `method_missing` répond à n'importe quel prédicat.
  #
  # Les prédicats qui existent vraiment — `blank?`, `present?`, `frozen?` —
  # restent délégués : `Delegator` en a retiré la plupart de sa propre table de
  # méthodes, et les intercepter ici rendrait une réponse fausse.
  def method_missing(name, *args, &block)
    env = current_env
    asked = env && environment_predicate(name)
    return asked == env.to_s if asked

    super
  end

  def respond_to_missing?(name, include_private = false)
    (!current_env.nil? && !environment_predicate(name).nil?) || super
  end

  private

    # L'environnement interrogé par un prédicat, ou nil si `name` n'en est pas
    # un.
    def environment_predicate(name)
      return nil if ::String.method_defined?(name) || ::Object.method_defined?(name)

      name.to_s[/\A([a-z_]+)\?\z/, 1]
    end
end
