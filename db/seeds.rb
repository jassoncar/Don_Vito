admin = User.find_or_initialize_by(email: "admin@comercio.local")
admin.password = "Cambiar123!"
admin.password_confirmation = "Cambiar123!"
admin.role = :admin
admin.save!

inventory = User.find_or_initialize_by(email: "inventario@comercio.local")
inventory.password = "Cambiar123!"
inventory.password_confirmation = "Cambiar123!"
inventory.role = :inventory_manager
inventory.save!

cashier = User.find_or_initialize_by(email: "caja@comercio.local")
cashier.password = "Cambiar123!"
cashier.password_confirmation = "Cambiar123!"
cashier.role = :cashier
cashier.save!

bebidas = Category.find_or_create_by!(name: "Bebidas") { |c| c.description = "Bebidas y refrescos" }
abarrotes = Category.find_or_create_by!(name: "Abarrotes") { |c| c.description = "Productos de consumo" }
marca = Brand.find_or_create_by!(name: "Genérica")
[
  ["BEB-001","Agua embotellada 1 L",bebidas,3.50,6.00,40],
  ["BEB-002","Refresco 600 ml",bebidas,18.00,25.00,24],
  ["ABA-001","Arroz 1 kg",abarrotes,28.00,35.00,18],
  ["ABA-002","Aceite 1 L",abarrotes,48.00,62.00,12]
].each do |sku,name,category,cost,price,stock|
  Product.find_or_create_by!(sku: sku) do |p|
    p.name=name; p.category=category; p.brand=marca; p.cost_price=cost; p.sale_price=price
    p.stock=stock; p.minimum_stock=5; p.active=true
  end
end
Supplier.find_or_create_by!(name: "Distribuidora Demo") { |s| s.phone = "0000-0000"; s.active = true }
Customer.find_or_create_by!(name: "Cliente de mostrador")
puts "Datos demo creados. Cambia las contraseñas de ejemplo antes de usar el sistema."
