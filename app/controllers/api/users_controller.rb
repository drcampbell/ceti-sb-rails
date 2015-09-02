class API::UsersController < API::ApplicationController

  #before_filter :authenticate_user!
  #before_action :correct_user,   only: [:update, :destroy]
  #before_action :admin_user,     only: :destroy
  respond_to :json

  def index
    puts params
    @search = Sunspot.search(User) do
      fulltext params[:search]
      paginate(page: params[:page])
    end
    if params[:search]
      @users = @search.results
    elsif params[:tag]
      @users = User.tagged_with(params[:tag]).paginate(page: params[:page])
    else
      @users = User.all.paginate(page: params[:page])
    end

    results = Array.new(@users.count) { Hash.new }
    for i in 0..results.count-1
      if @users[i].role == "Teacher" || @users[i].role == "Both"
        association = handle_abbr(School.find(@users[i].school_id).school_name)
      elsif @users[i].role == "Speaker"
        association == @users[i].business
      end
      results[i] = {"id" => @users[i].id, "name" => @users[i].name, "association" => association}
    end

    render json: {:users => results}.as_json

  end

  def show
    @user = User.find(params[:id])

    # if @user.school_id && @user.school_id != ""
    #   school_name =School.find(@user.school_id).school_name
    # else
    #   school_name = nil
    # end

    # user_message = {id: @user.id, name:@user.name, role:@user.role, 
    #                 grades:@user.grades, job_title:@user.job_title,
    #                 business:@user.business, biography:@user.biography,
    #                 category:@user.speaking_category, school_id:@user.school_id,
    #                 school_name:school_name}
    render json: format_user(@user)

  end

  def format_user(user)
    if user.school_id && user.school_id != ""
      school_name =School.find(user.school_id).school_name
    else
      school_name = nil
    end

    user_message = {id: user.id, name:user.name, role:user.role, 
                    grades:user.grades, job_title:user.job_title,
                    business:user.business, biography:user.biography,
                    category:user.speaking_category, school_id:user.school_id,
                    school_name:school_name}
    return user_message
  end

  def edit
    @user = current_user
  end

  def update
    @user = User.find(current_user.id)
    if @user.update_attributes(secure_params)
      render json: {state:0, user:format_user(@user)}
    else
      render json: {state:1}
    end
  end

  def destroy
    User.find(params[:id]).destroy
    respond_to do |format|
      format.html do
        flash[:success] = 'User deleted'
        redirect_to users_path
      end
      format.json {render :json => {:state => {:code => 0, status: :ok} }}
    end
  end

  def send_message
    UserMailer.send_message(current_user.id, params[:id], params[:user_message]).deliver_now
    sns = Aws::SNS::Client.new
    sns.publish(target_arn: Device.find_by(user_id: params[:id]).endpoint_arn, message: "hi".to_json, message_structure:"json")
    render json: {state:0}
  end

  def register_device
    device = Device.find_by(user_id: current_user.id, device_name: params[:device_name])
    if device != nil
      device.update(token: params[:token])
    else
      device = {user_id: current_user.id, device_name: params[:device_name], token: params[:token] }
      device = Device.create(device)
    end
    render json: {state: 0}

    begin
      sns = Aws::SNS::Client.new
      endpoint = sns.create_platform_endpoint(
        platform_application_arn: ENV["SNS_APP_ARN"],
        token: device.token,
        attributes: { "user_id" => "#{device.user_id}"}
      )
      device.update(endpoint_arn: endpoint[:endpoint_arn])
    rescue
    end
  end
  
  private

  # Confirms an admin user.
  def admin_user
    redirect_to(root_url) unless @user.role == 'Admin'
  end

  def secure_params
    params.require(:user).permit(:id, :role, :name, :email, :biography, :school_id, :grades, :job_title, :business, :current_password, :tag_list, location_attributes: [:user_id, :address])
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user == @user
  end
end
