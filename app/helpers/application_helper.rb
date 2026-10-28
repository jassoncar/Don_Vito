module ApplicationHelper
  def money(value)
    "#{Setting.get('currency_symbol', 'C$')} #{number_with_precision(value.to_f, precision: 2, delimiter: ',', separator: '.')}"
  end

  def amount(value)
    number_with_precision(value.to_f, precision: 2, delimiter: ",", separator: ".")
  end

  def badge(text, color = "secondary")
    content_tag(:span, text, class: "badge bg-#{color}")
  end

  def status_color(status)
    { "completed" => "success", "received" => "success", "ordered" => "warning",
      "returned" => "warning", "cancelled" => "secondary" }[status] || "secondary"
  end

  def app_name
    Setting.get("company_name", "Licorería")
  end

  def field_error(record, name)
    message = record.errors[name].first
    content_tag(:div, message, class: "invalid-feedback d-block") if message
  end

  def input_class(record, name)
    record.errors[name].any? ? "is-invalid" : ""
  end

  # Celda de la tabla genérica (CRUD).
  def crud_cell(record, col)
    value = col[:key].split(".").inject(record) { |object, method| object&.public_send(method) }

    case col[:type]
    when :bool then badge(value ? "Activo" : "Inactivo", value ? "success" : "secondary")
    when :image
      if value.present?
        tag.img(src: value, alt: "", class: "thumb", loading: "lazy")
      else
        content_tag(:span, content_tag(:i, "", class: "bi bi-image"), class: "thumb-ph")
      end
    when :money then content_tag(:span, money(value), class: "num")
    when :stock then badge(value, record.low_stock? ? "danger" : "success")
    else value.presence || "—"
    end
  end

  # Menú lateral: grupo => [[etiqueta, icono, ruta, permiso, activo?]]
  def menu_groups
    received = params[:status] == "received"
    {
      "General" => [
        ["Dashboard", "bi-speedometer2", dashboard_path, nil, controller_name == "dashboard"]
      ],
      "Ventas" => [
        ["Punto de venta", "bi-cart-check", pos_path, "sales.create", action_name == "pos"],
        ["Ventas", "bi-receipt", sales_path, "sales.view", controller_name == "sales" && action_name != "pos"],
        ["Devoluciones", "bi-arrow-return-left", returns_path, "returns.view", controller_name == "sale_returns"],
        ["Clientes", "bi-people", customers_path, "customers.view", controller_name == "customers"]
      ],
      "Catálogo" => [
        ["Productos", "bi-box-seam", products_path, "products.view", controller_name == "products"],
        ["Categorías", "bi-tags", categories_path, "categories.view", controller_name == "categories"],
        ["Marcas", "bi-bookmark-star", brands_path, "brands.view", controller_name == "brands"]
      ],
      "Compras e inventario" => [
        ["Proveedores", "bi-truck", suppliers_path, "suppliers.view", controller_name == "suppliers"],
        ["Órdenes de compra", "bi-bag-plus", purchases_path, "purchases.view", controller_name == "purchases" && !received],
        ["Órdenes recibidas", "bi-bag-check", purchases_path(status: "received"), "purchases.view", controller_name == "purchases" && received],
        ["Existencias", "bi-boxes", inventory_path, "inventory.view", controller_name == "inventory"],
        ["Ajustes de inventario", "bi-sliders", adjustments_path, "inventory.view", controller_name == "adjustments"]
      ],
      "Análisis" => [
        ["Reportes", "bi-graph-up", reports_path, "reports.view", controller_name == "reports"]
      ],
      "Administración" => [
        ["Usuarios", "bi-person-gear", users_path, "users.view", controller_name == "users"],
        ["Roles y permisos", "bi-shield-lock", roles_path, "roles.view", controller_name == "roles"],
        ["Configuración", "bi-gear", edit_settings_path, "settings.edit", controller_name == "settings"],
        ["Auditoría", "bi-clipboard-data", audit_path, "audit.view", controller_name == "audit_logs"]
      ]
    }
  end
end
