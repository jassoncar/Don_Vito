class ApplicationController < ActionController::Base
  before_action :require_login
  before_action :set_current

  helper_method :current_user, :can?

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.includes(:role).find_by(id: session[:user_id])
  end

  def can?(permission)
    current_user.present? && current_user.can?(permission)
  end

  def require_login
    return if current_user&.is_active

    inactive = current_user.present?
    reset_session
    flash[:alert] = "Su usuario está inactivo. Contacte al administrador." if inactive
    redirect_to login_path
  end

  def set_current
    Current.user = current_user
    Current.ip = request.remote_ip
  end

  def require_permission!(permission)
    render "shared/forbidden", status: :forbidden unless can?(permission)
  end

  # Paginación simple: devuelve el scope de la página actual y llena @pagination.
  def paginate(scope, per: 15)
    page = [params[:page].to_i, 1].max
    total = scope.count
    pages = [(total / per.to_f).ceil, 1].max
    page = [page, pages].min
    @pagination = { page: page, pages: pages, total: total }
    scope.offset((page - 1) * per).limit(per)
  end

  def to_decimal(value)
    text = value.to_s.strip
    return nil if text.empty?

    number = BigDecimal(text)
    number.finite? ? number : nil
  rescue ArgumentError
    nil
  end

  # Convierte items[0][product_id]... en un arreglo de hashes.
  def raw_items(key = :items)
    raw = params[key]
    raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h.values : []
  end
end
