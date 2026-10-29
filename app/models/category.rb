class Category < ApplicationRecord
  has_many :products, dependent: :restrict_with_exception
  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
