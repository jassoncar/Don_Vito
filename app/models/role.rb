class Role < ApplicationRecord
  include Auditable

  has_and_belongs_to_many :permissions
  has_many :users

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  def admin?
    slug == "admin"
  end
end
