class ProfileController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.name = params[:name].to_s.strip

    if params[:password].present?
      if !@user.authenticate(params[:current_password].to_s)
        @user.errors.add(:base, "La contraseña actual es incorrecta.")
      elsif params[:password] != params[:password_confirmation]
        @user.errors.add(:base, "La confirmación de la contraseña no coincide.")
      else
        @user.password = params[:password]
      end
    end

    if @user.errors.empty? && @user.save
      redirect_to edit_profile_path, notice: "Perfil actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
