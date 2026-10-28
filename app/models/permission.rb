class Permission < ApplicationRecord
  CRUD = { "view" => "Ver", "create" => "Crear", "edit" => "Editar", "delete" => "Eliminar" }.freeze

  # módulo => [etiqueta, { acción => etiqueta }]
  CATALOG = {
    "products" => ["Productos", CRUD],
    "categories" => ["Categorías", CRUD],
    "brands" => ["Marcas", CRUD],
    "suppliers" => ["Proveedores", CRUD],
    "customers" => ["Clientes", CRUD],
    "purchases" => ["Compras y órdenes recibidas", { "view" => "Ver", "create" => "Crear", "receive" => "Recibir", "cancel" => "Cancelar" }],
    "inventory" => ["Inventario y ajustes", { "view" => "Ver", "adjust" => "Ajustar" }],
    "sales" => ["Ventas / POS", { "view" => "Ver", "create" => "Vender (POS)", "cancel" => "Anular" }],
    "returns" => ["Devoluciones", { "view" => "Ver", "create" => "Crear" }],
    "users" => ["Usuarios", CRUD],
    "roles" => ["Roles y permisos", CRUD],
    "reports" => ["Reportes", { "view" => "Ver y exportar" }],
    "settings" => ["Configuración", { "edit" => "Editar" }],
    "audit" => ["Auditoría", { "view" => "Ver" }]
  }.freeze

  has_and_belongs_to_many :roles
end
