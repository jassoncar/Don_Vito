class Sale < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :user
  has_many :sale_items, dependent: :destroy
  enum :payment_method, { cash: 0, card: 1, transfer: 2, other: 3 }, default: :cash
  enum :status, { completed: 0, cancelled: 1 }, default: :completed
  validates :reference, presence: true, uniqueness: true
end
