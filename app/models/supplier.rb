class Supplier < ApplicationRecord
  has_many :purchases, dependent: :restrict_with_exception
  validates :name, presence: true
end
