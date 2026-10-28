class User < ApplicationRecord
  include Auditable

  has_secure_password
  belongs_to :role, optional: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true
  validates :password, length: { minimum: 8 }, allow_blank: true

  def admin?
    role&.slug == "admin"
  end

  def can?(permission)
    return true if admin?

    @permission_names ||= role ? role.permissions.pluck(:name) : []
    @permission_names.include?(permission)
  end
end
