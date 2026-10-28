# Datos iniciales: permisos, roles, usuarios de demostración, configuración y catálogo.
# Es idempotente: puede ejecutarse varias veces.
AuditLog.enabled = false

begin
  # --- Permisos ----------------------------------------------------------
  Permission::CATALOG.each do |mod, (_label, actions)|
    actions.each do |action, label|
      permission = Permission.find_or_initialize_by(name: "#{mod}.#{action}")
      permission.update!(label: label, module_key: mod)
    end
  end

  # --- Roles -------------------------------------------------------------
  roles = {
    "admin" => ["Administrador", "Acceso total al sistema", Permission.pluck(:name)],
    "staff" => ["Staff / Vendedor", "Ventas, clientes y devoluciones",
                %w[sales.view sales.create returns.view returns.create customers.view customers.create
                   customers.edit products.view categories.view brands.view]],
    "inventory" => ["Encargado de inventario", "Catálogo, compras, inventario y reportes",
                    %w[products.view products.create products.edit products.delete
                       categories.view categories.create categories.edit categories.delete
                       brands.view brands.create brands.edit brands.delete
                       suppliers.view suppliers.create suppliers.edit suppliers.delete
                       purchases.view purchases.create purchases.receive purchases.cancel
                       inventory.view inventory.adjust reports.view]]
  }

  roles.each do |slug, (name, description, permission_names)|
    role = Role.find_or_initialize_by(slug: slug)
    role.update!(name: name, description: description)
    role.permissions = Permission.where(name: permission_names)
  end

  # --- Usuarios de demostración -----------------------------------------
  [
    ["Administrador", "admin@licoreria.test", "admin", "Admin12345!"],
    ["Vendedor Demo", "staff@licoreria.test", "staff", "Staff12345!"],
    ["Encargado Inventario", "inventario@licoreria.test", "inventory", "Inventario12345!"]
  ].each do |name, email, slug, password|
    user = User.find_or_initialize_by(email: email)
    user.update!(name: name, password: password, role: Role.find_by!(slug: slug), is_active: true)
  end

  # --- Configuración -----------------------------------------------------
  Setting.put(
    "company_name" => "Don Vito Licorería",
    "company_tax_id" => "J0000000000000",
    "company_address" => "Managua, Nicaragua",
    "company_phone" => "+505 8888-8888",
    "currency_symbol" => "C$",
    "receipt_footer" => "¡Gracias por su compra! Beba con moderación."
  )

  # --- Catálogo de demostración -----------------------------------------
  ["Ron", "Whisky", "Vodka", "Tequila", "Cerveza", "Vino", "Licores y cremas"].each do |name|
    Category.find_or_create_by!(name: name)
  end

  ["Flor de Caña", "Johnnie Walker", "Absolut", "Smirnoff", "Jose Cuervo", "Tona", "Victoria",
   "Heineken", "Corona", "Casillero del Diablo", "Jägermeister", "Baileys"].each do |name|
    Brand.find_or_create_by!(name: name)
  end

  [
    ["Distribuidora Central S.A.", "Carlos Pérez", "+505 2222-1111", "ventas@distcentral.test"],
    ["Importadora Licores del Norte", "María López", "+505 2222-2222", "pedidos@licoresnorte.test"]
  ].each do |name, contact, phone, email|
    Supplier.find_or_create_by!(name: name) { |s| s.assign_attributes(contact_name: contact, phone: phone, email: email) }
  end

  Customer.find_or_create_by!(name: "Cliente de ejemplo") { |c| c.phone = "+505 8777-7777" }

  supplier = Supplier.order(:id).first

  # [sku, nombre, categoría, marca, costo, precio, stock, mínimo]
  [
    ["LIC-0001", "Flor de Caña 4 años 750 ml", "Ron", "Flor de Caña", 190, 260, 30, 6],
    ["LIC-0002", "Flor de Caña 7 años 750 ml", "Ron", "Flor de Caña", 320, 420, 24, 6],
    ["LIC-0003", "Flor de Caña 12 años 750 ml", "Ron", "Flor de Caña", 560, 720, 12, 4],
    ["LIC-0004", "Johnnie Walker Red Label 750 ml", "Whisky", "Johnnie Walker", 480, 620, 18, 5],
    ["LIC-0005", "Johnnie Walker Black Label 750 ml", "Whisky", "Johnnie Walker", 980, 1250, 4, 5],
    ["LIC-0006", "Absolut Vodka 750 ml", "Vodka", "Absolut", 450, 590, 15, 5],
    ["LIC-0007", "Smirnoff Vodka 750 ml", "Vodka", "Smirnoff", 330, 440, 20, 5],
    ["LIC-0008", "Jose Cuervo Especial 750 ml", "Tequila", "Jose Cuervo", 420, 560, 14, 5],
    ["LIC-0009", "Tona lata 355 ml", "Cerveza", "Tona", 22, 32, 240, 48],
    ["LIC-0010", "Victoria Clásica lata 355 ml", "Cerveza", "Victoria", 22, 32, 240, 48],
    ["LIC-0011", "Heineken botella 330 ml", "Cerveza", "Heineken", 35, 50, 96, 24],
    ["LIC-0012", "Corona botella 355 ml", "Cerveza", "Corona", 36, 52, 96, 24],
    ["LIC-0013", "Casillero del Diablo Cabernet Sauvignon 750 ml", "Vino", "Casillero del Diablo", 280, 380, 18, 6],
    ["LIC-0014", "Jägermeister 700 ml", "Licores y cremas", "Jägermeister", 780, 980, 8, 3],
    ["LIC-0015", "Baileys Original 750 ml", "Licores y cremas", "Baileys", 700, 900, 9, 3]
  ].each_with_index do |(sku, name, category, brand, cost, price, stock, min), index|
    next if Product.exists?(sku: sku)

    Product.create!(
      sku: sku, barcode: format("7440000%06d", index + 1), name: name,
      category: Category.find_by!(name: category), brand: Brand.find_by!(name: brand), supplier: supplier,
      cost_price: cost, sale_price: price, tax_rate: 15, min_stock: min, is_active: true,
      initial_stock: stock
    )
  end
ensure
  AuditLog.enabled = true
end
