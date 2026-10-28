module Codeable
  # Asigna un código correlativo (ej. VTA-000012) usando el id del registro, sin callbacks.
  def assign_code!(prefix)
    update_column(:code, format("%s-%06d", prefix, id))
  end
end
