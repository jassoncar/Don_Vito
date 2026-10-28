class Customer < ApplicationRecord
  include Auditable

  has_many :sales

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
