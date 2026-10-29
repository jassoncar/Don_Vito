class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  validates :action, :record_type, presence: true
end
