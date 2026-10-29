class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  enum :role, { admin: 0, cashier: 1, inventory_manager: 2 }, default: :cashier
  has_many :inventory_movements, dependent: :restrict_with_exception
  has_many :sales, dependent: :restrict_with_exception
  has_many :purchases, dependent: :restrict_with_exception
end
