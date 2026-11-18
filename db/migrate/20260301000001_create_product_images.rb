class CreateProductImages < ActiveRecord::Migration[7.1]
  class MigProduct < ActiveRecord::Base
    self.table_name = "products"
  end

  class MigImage < ActiveRecord::Base
    self.table_name = "product_images"
  end

  TYPES = { "jpg" => "image/jpeg", "jpeg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp" }.freeze

  def up
    create_table :product_images do |t|
      t.references :product, null: false, foreign_key: true, index: { unique: true }
      t.string :content_type, null: false
      t.binary :data, null: false, limit: 4.megabytes
      t.timestamps
    end

    # Pasa las imágenes que estaban como archivos (public/uploads/products) a la base de datos.
    dir = Rails.root.join("public", "uploads", "products")
    MigProduct.reset_column_information
    MigProduct.where.not(image: [nil, ""]).find_each do |product|
      path = dir.join(File.basename(product.image.to_s))
      type = TYPES[File.extname(path.to_s).delete(".").downcase]

      if type && File.exist?(path)
        MigImage.create!(product_id: product.id, content_type: type, data: File.binread(path))
      else
        product.update_columns(image: nil)
      end
    end
  end

  def down
    drop_table :product_images
  end
end
