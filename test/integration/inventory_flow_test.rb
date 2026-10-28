require "test_helper"

class InventoryFlowTest < ActionDispatch::IntegrationTest
  setup do
    load Rails.root.join("db/seeds.rb")
  end

  def login(email, password)
    post login_path, params: { email: email, password: password }
  end

  test "invitado es redirigido al login" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "admin inicia sesión y ve el dashboard" do
    login "admin@licoreria.test", "Admin12345!"
    assert_redirected_to dashboard_path
    get dashboard_path
    assert_response :success
  end

  test "vendedor no puede entrar al módulo de usuarios" do
    login "staff@licoreria.test", "Staff12345!"
    get users_path
    assert_response :forbidden
  end

  test "una venta descuenta stock y se rechaza la sobreventa" do
    login "admin@licoreria.test", "Admin12345!"
    product = Product.find_by!(sku: "LIC-0001")
    before = product.stock

    post sales_path, params: { payment_method: "cash", amount_paid: 1000,
                               items: { "0" => { product_id: product.id, quantity: 2 } } }
    assert_equal before - 2, product.reload.stock
    assert_equal 1, Sale.count

    post sales_path, params: { payment_method: "cash", amount_paid: 999_999,
                               items: { "0" => { product_id: product.id, quantity: 9999 } } }
    assert_response :unprocessable_entity
    assert_equal before - 2, product.reload.stock
  end

  test "recibir una orden de compra aumenta el stock" do
    login "admin@licoreria.test", "Admin12345!"
    product = Product.find_by!(sku: "LIC-0005")
    before = product.stock

    post purchases_path, params: { supplier_id: Supplier.first.id, ordered_at: Time.zone.today.to_s,
                                   items: { "0" => { product_id: product.id, quantity: 10, unit_cost: 900 } } }
    purchase = Purchase.first
    assert_equal before, product.reload.stock

    post receive_purchase_path(purchase)
    assert_equal before + 10, product.reload.stock
    assert_equal "received", purchase.reload.status
  end

  test "la transferencia exige banco y referencia" do
    login "admin@licoreria.test", "Admin12345!"
    product = Product.find_by!(sku: "LIC-0002")
    items = { "0" => { product_id: product.id, quantity: 1 } }

    post sales_path, params: { payment_method: "transfer", items: items }
    assert_response :unprocessable_entity
    assert_equal 0, Sale.count

    post sales_path, params: { payment_method: "transfer", transfer_bank: "BAC", transfer_reference: "123456", items: items }
    assert_equal 1, Sale.count
    assert_equal "BAC", Sale.last.payment_bank
    assert_equal "123456", Sale.last.payment_reference
  end

  test "importa productos desde un CSV" do
    login "admin@licoreria.test", "Admin12345!"
    file = Tempfile.new(["productos", ".csv"])
    file.write("SKU,Nombre,Categoría,Precio,Stock inicial\nTST-1,Producto de prueba,Ron,100,5\n")
    file.close

    upload = Rack::Test::UploadedFile.new(file.path, "text/csv")
    post product_import_path, params: { file: upload, update_existing: "1" }

    product = Product.find_by(sku: "TST-1")
    assert product, "el producto debería haberse creado"
    assert_equal 5, product.stock
  end
end
