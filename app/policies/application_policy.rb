class ApplicationPolicy
  attr_reader :user, :record
  def initialize(user, record)
    @user, @record = user, record
  end
  def index? = user.present?
  def show? = user.present?
  def create? = user&.admin? || user&.inventory_manager?
  def new? = create?
  def update? = user&.admin? || user&.inventory_manager?
  def edit? = update?
  def destroy? = user&.admin?
  class Scope
    attr_reader :user, :scope
    def initialize(user, scope); @user, @scope = user, scope; end
    def resolve = scope.all
  end
end
