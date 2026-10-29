class ProductsController < CrudController
  private

  def model_class = Product
  def permission_prefix = "products"
  def title = "Productos"
  def singular = "Producto"
  def includes_list = %i[category brand]
  def searchable = %w[name sku barcode]

  def extra_actions
    [{ label: "Importar desde archivo", path: new_product_import_path, icon: "bi-upload", permission: "products.create" }]
  end

  def columns
    [
      { key: "image_url", label: "", type: :image },
      { key: "sku", label: "SKU" },
      { key: "name", label: "Producto" },
      { key: "category.name", label: "Categoría" },
      { key: "brand.name", label: "Marca" },
      { key: "sale_price", label: "Precio", type: :money },
      { key: "stock", label: "Stock", type: :stock },
      { key: "is_active", label: "Estado", type: :bool }
    ]
  end

  def fields(record = nil)
    fields = {
      sku: { label: "SKU", type: :text, col: 4 },
      barcode: { label: "Código de barras", type: :text, col: 4 },
      name: { label: "Nombre", type: :text, col: 4 },
      category_id: { label: "Categoría", type: :select, col: 4, placeholder: "Seleccione...",
                     options: Category.where(is_active: true).order(:name).pluck(:name, :id) },
      brand_id: { label: "Marca", type: :select, col: 4, placeholder: "Sin marca",
                  options: Brand.where(is_active: true).order(:name).pluck(:name, :id) },
      supplier_id: { label: "Proveedor", type: :select, col: 4, placeholder: "Sin proveedor",
                     options: Supplier.where(is_active: true).order(:name).pluck(:name, :id) },
      cost_price: { label: "Precio de costo", type: :number, step: "0.01", col: 3, default: 0 },
      sale_price: { label: "Precio de venta", type: :number, step: "0.01", col: 3, default: 0 },
      tax_rate: { label: "Impuesto (%)", type: :number, step: "0.01", col: 3, default: 15 },
      min_stock: { label: "Stock mínimo", type: :number, step: "1", col: 3, default: 5 }
    }
    fields[:initial_stock] = { label: "Stock inicial", type: :number, step: "1", col: 3, default: 0 } if record.nil?
    fields[:description] = { label: "Descripción", type: :textarea, col: 12 }
    fields[:image_file] = { label: "Imagen del producto (JPG, PNG o WEBP, máx. 2 MB)", type: :file, col: 12 }
    fields[:remove_image] = { label: "Quitar la imagen actual", type: :checkbox, col: 12 } if record&.image.present?
    fields[:is_active] = { label: "Activo (disponible para la venta)", type: :checkbox, default: true, col: 12 }
    fields
  end

  def delete_error(record)
    return unless record.sale_items.exists? || record.purchase_items.exists?

    "No se puede eliminar: el producto tiene ventas o compras registradas. Desactívelo en su lugar."
  end
end
