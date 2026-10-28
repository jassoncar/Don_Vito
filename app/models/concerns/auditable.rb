module Auditable
  extend ActiveSupport::Concern

  included do
    after_create { AuditLog.record("created", self) }
    after_destroy { AuditLog.record("deleted", self) }
    after_update do
      changes = saved_changes.except("updated_at")
      if changes.any?
        visible = changes.except("password_digest")
        AuditLog.record("updated", self,
                        before: visible.transform_values(&:first),
                        after: visible.transform_values(&:last))
      end
    end
  end
end
