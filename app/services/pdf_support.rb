# Las fuentes estándar de Prawn solo soportan Windows-1252: se reemplazan los demás caracteres.
module PdfSupport
  def self.clean(text)
    text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end

  def self.cell(value)
    if value.is_a?(Float)
      ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2, delimiter: ",", separator: ".")
    else
      clean(value)
    end
  end
end
