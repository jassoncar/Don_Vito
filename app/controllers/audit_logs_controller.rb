class AuditLogsController < ApplicationController
  before_action { require_permission!("audit.view") }

  def index
    scope = AuditLog.includes(:user).order(id: :desc)
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(action: params[:action_filter]) if params[:action_filter].present?
    scope = scope.where("audit_logs.created_at >= ?", Time.zone.parse(params[:from]).beginning_of_day) if valid_date?(params[:from])
    scope = scope.where("audit_logs.created_at <= ?", Time.zone.parse(params[:to]).end_of_day) if valid_date?(params[:to])
    if params[:q].present?
      scope = scope.where("description LIKE ?", "%#{AuditLog.sanitize_sql_like(params[:q].to_s.strip)}%")
    end

    @logs = paginate(scope, per: 25)
    @users = User.order(:name)
  end

  private

  def valid_date?(value)
    Date.iso8601(value.to_s)
    true
  rescue ArgumentError
    false
  end
end
