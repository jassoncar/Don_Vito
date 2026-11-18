class ProductImagesController < ApplicationController
  def show
    image = ProductImage.find_by!(product_id: params[:id])
    expires_in 1.year, public: false
    send_data image.data, type: image.content_type, disposition: "inline"
  end
end
