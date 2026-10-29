class AuditLog < ApplicationRecord
  # Permite desactivar la auditoría (seeds, pruebas).
  cattr_accessor :enabled, default: true

  ACTIONS = {
    "created" => "Creó", "updated" => "Actualizó", "deleted" => "Eliminó",
    "login" => "Inicio de sesión", "logout" => "Cierre de sesión",
    "received" => "Recibió", "cancelled" => "Canceló"
  }.freeze

  belongs_to :user, optional: true

  # Suspende la auditoría solo en el hilo actual (por ejemplo durante una importación masiva).
  def self.suppress
    previous = Thread.current[:audit_suppressed]
    Thread.current[:audit_suppressed] = true
    yield
  ensure
    Thread.current[:audit_suppressed] = previous
  end

  def self.record(action, record = nil, before: nil, after: nil, description: nil)
    return if !enabled || Thread.current[:audit_suppressed]

    before = before.presence
    after = after.presence
    if description.nil? && record
      label = record.try(:name) || record.try(:code) || "##{record.id}"
      description = "#{ACTIONS[action] || action} #{record.class.name}: #{label}"
    end

    create!(
      user_id: Current.user&.id,
      action: action,
      auditable_type: record&.class&.name,
      auditable_id: record&.id,
      description: description || action,
      old_values: before,
      new_values: after,
      ip_address: Current.ip
    )
  end
end
