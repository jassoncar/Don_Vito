class SettingsController < ApplicationController
  KEYS = {
    "company_name" => "Nombre del negocio",
    "company_tax_id" => "RUC / Identificación fiscal",
    "company_address" => "Dirección",
    "company_phone" => "Teléfono",
    "currency_symbol" => "Símbolo de moneda",
    "receipt_footer" => "Mensaje al pie del comprobante"
  }.freeze

  before_action { require_permission!("settings.edit") }

  def edit
    @labels = KEYS
    @values = KEYS.keys.index_with { |key| Setting.get(key, "") }
  end

  def update
    values = KEYS.keys.index_with { |key| params[key].to_s.strip }

    if values["company_name"].blank? || values["currency_symbol"].blank?
      @errors = ["El nombre del negocio y el símbolo de moneda son obligatorios."]
      @labels = KEYS
      @values = values
      return render :edit, status: :unprocessable_entity
    end

    Setting.put(values)
    redirect_to edit_settings_path, notice: "Configuración guardada."
  end
end
