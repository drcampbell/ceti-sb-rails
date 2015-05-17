class SessionsController < Devise::SessionsController
# before_filter :ensure_params_exist
prepend_before_filter :require_no_authentication, :only => [:create ]

respond_to :json

def create
  respond_to do |format|
    format.html do
      self.resource = warden.authenticate!(auth_options)
      set_flash_message(:notice, :signed_in) if is_flashing_format?
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
    format.json do
      email = params[:session][:email] if params[:session]
      password = params[:session][:password] if params[:session]
      id = User.find_by(email: email).try(:id) if email.presence
      if email.nil? or password.nil?
        render status: 400, json: { message: 'The request MUST contain the user email and password.' }
        return
      end
      user = User.find_by(email: email)
      if user
        if user.valid_password? password
          render status: 200, json: { email: user.email, id: id }
        else
          render status: 401, json: { message: 'Invalid email or password.' }
        end
      else
        render status: 401, json: { message: 'Invalid email or password.' }
      end
    end
  end
end

def destroy
  respond_to do |format|
    format.html do
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
      yield if block_given?
      respond_to_on_destroy
    end
    format.json do
      if user.nil?
        render status: 404, json: { message: 'Invalid token.' }
      else
        user.save!
        render status: 204, json: nil
      end
    end
  end
end

  protected
    def ensure_params_exist
      return unless params[:user_login].blank?
      render :json=>{:success=>false, :message=> 'missing user_login parameter'}, :status=>422
    end

    def invalid_login_attempt
      warden.custom_failure!
      render :json=> {:success=>false, :message=> 'Error with your login or password'}, :status=>401
    end

    def sign_in_params
      devise_parameter_sanitizer.sanitize(:sign_in)
    end

    def serialize_options(resource)
      methods = resource_class.authentication_keys.dup
      methods = methods.keys if methods.is_a?(Hash)
      methods << :password if resource.respond_to?(:password)
      { methods: methods, only: [:password] }
    end
    def auth_options
      { scope: resource_name, recall: "#{controller_path}#new" }
    end


    private
    # Check if there is no signed in user before doing the sign out.
    #
    # If there is no signed in user, it will set the flash message and redirect
    # to the after_sign_out path.
      def verify_signed_out_user
        if all_signed_out?
          set_flash_message :notice, :already_signed_out if is_flashing_format?
          respond_to_on_destroy
        end
      end
      def all_signed_out?
        users = Devise.mappings.keys.map { |s| warden.user(scope: s, run_callbacks: false) }
        users.all?(&:blank?)
      end
      def respond_to_on_destroy
    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) { redirect_to after_sign_out_path_for(resource_name) }
    end
  end
end