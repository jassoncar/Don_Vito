class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!
  rescue_from Pundit::NotAuthorizedError do
    redirect_to root_path, alert: "No tienes permisos para realizar esta acción."
  end
  private
  def audit!(action, record)
    AuditLog.create!(user: current_user, action: action, record_type: record.class.name,
                     record_id: record.id, details: { attributes: record.saved_changes.except("updated_at") }.to_json)
  end
end
