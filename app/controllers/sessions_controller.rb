class SessionsController < ApplicationController
  skip_before_action :require_login

  layout false

  def new
    redirect_to dashboard_path if current_user&.is_active
  end

  def create
    email = params[:email].to_s.strip.downcase
    key = "login:#{email}:#{request.remote_ip}"
    attempts = Rails.cache.read(key).to_i

    if attempts >= 5
      @error = "Demasiados intentos. Intente nuevamente en un minuto."
      return render :new, status: :too_many_requests
    end

    user = User.find_by(email: email)

    if user&.is_active && user.authenticate(params[:password].to_s)
      Rails.cache.delete(key)
      reset_session
      session[:user_id] = user.id
      Current.user = user
      Current.ip = request.remote_ip
      AuditLog.record("login", description: "Inicio de sesión: #{user.email}")
      redirect_to dashboard_path
    else
      Rails.cache.write(key, attempts + 1, expires_in: 1.minute)
      @error = "Credenciales inválidas o usuario inactivo."
      @email = email
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    AuditLog.record("logout", description: "Cierre de sesión: #{current_user.email}") if current_user
    reset_session
    redirect_to login_path
  end
end
