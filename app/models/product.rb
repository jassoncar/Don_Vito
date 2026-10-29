class Product < ApplicationRecord
  belongs_to :category
  belongs_to :brand, optional: true
  has_many :purchase_items, dependent: :restrict_with_exception
  has_many :sale_items, dependent: :restrict_with_exception
  has_many :inventory_movements, dependent: :restrict_with_exception
  validates :sku, presence: true, uniqueness: true
  validates :name, presence: true
  validates :cost_price, :sale_price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, :minimum_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  scope :active, -> { where(active: true) }
  scope :low_stock, -> { where("stock <= minimum_stock") }
end
