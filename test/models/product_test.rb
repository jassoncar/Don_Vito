require "test_helper"
class ProductTest < ActiveSupport::TestCase
  test "rechaza existencias negativas" do
    category = Category.create!(name: "Prueba")
    product = Product.new(sku: "NEG-1", name: "Prueba", category: category, cost_price: 1, sale_price: 2, stock: -1, minimum_stock: 0)
    assert_not product.valid?
    assert_includes product.errors[:stock], "must be greater than or equal to 0"
  end
end
