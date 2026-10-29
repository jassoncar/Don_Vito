class Customer < ApplicationRecord
  has_many :sales, dependent: :nullify
  validates :name, presence: true
end
