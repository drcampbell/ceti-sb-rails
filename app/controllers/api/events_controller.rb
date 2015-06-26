class API::EventsController < API::ApplicationController
  before_action :set_event,           only: [:show]
  #before_action :authenticate_user!
  before_action :teacher_user,        only: [:create]
  before_action :correct_user,        only: [:edit, :update]
  before_action :admin_user,          only: :destroy
  respond_to :json

  def index
    if not user_signed_in?
      redirect_to :signin
    return
    end

    @search = Sunspot.search(Event) do
        #with(:user_id, params[:user].to_i)
        fulltext(params[:search])
         with(:event_start).less_than(Time.zone.now)    
       facet(:event_month)
        with(:event_month, params[:month]) if params[:month].present?
        paginate(page: params[:page])
    end

    if params[:search]# || params[:user]
      @events = @search.results
    elsif params[:tag]
      @events = Event.tagged_with(params[:tag]).paginate(page: params[:page])
    else
      @events = @search.results
    end

    results = Array.new(@events.count) { Hash.new }
    for i in 0..@events.count-1
      results[i] = {"id" => @events[i].id, "event_title" => @events[i].title, "event_start" => @events[i].event_start}
    end

    render json: {:events => results}.as_json
  end

  def show
    if user_signed_in?
      @event = Event.find(params[:id])
      school_name = nil
      user_name = nil
      if @event.school_id
        school_name = School.find(@event.school_id).school_name
      end
      if @event.user_id
        user_name = User.find(@event.user_id).name
      end

      result = @event.attributes
      result[:user_name] = user_name
      result[:school_name] = school_name
      render json: result.as_json
    end
  end

  def create
    if user_signed_in?
      @event = current_user.events.build(event_params)
      if @event.save
        render :json => {:state => {:code => 0}, :data => @event.to_json }
      else
        @feed_items = []
        render :json => {:state => {:code => 1, :messages => @event.errors.full_messages} }
      end
    else
      render_401
    end
  end

  def new
    if user_signed_in?
      if current_user.school_id > 1
        @event = current_user.events.build
      else
        redirect_to :choose
      end
    else
      redirect_to :signin
    end
  end

  def edit
    @event = Event.find(params[:id])
  end

  def update
    params = event_params
    @event = Event.find params[:id]

    respond_to do |format|
      if @event && @event.update(params)
        format.html do       
          flash[:success] = 'Event updated'
          redirect_to @event
        end
        format.json {render :json => {:state => {:code => 0}, status: :ok, :data => @event.to_json }}
        format.all { render_404 }
      elsif @event != nil
        format.html {render :edit, :alert => 'Unable to update event.'}
        format.json {render :json => {:state => {:code => 1, status: :error, :messages => @user.errors.full_messages} }}
        format.all {render_404}
      end
    end
  end

  def destroy
    if user_signed_in?
      @event = Event.find params[:id]
      respond_to do |format|
        format.html do
          @event.destroy
        end
        format.json do
          if @event.destroy
            render :json => {:state => {:code => 0}}
          else
            render :json => {:state => {:code => 1, :messages => @user.errors.full_messages} }
          end
        end
      end
    end
  end

  def claim_event
    @event = Event.find(params[:event_id])
    @event.claims.create!(:user_id => params[:user_id])
    redirect_to(root_url)
  end

  private
    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:content, :title, :event_start, :event_end, :school_id) #:tag_list, 
    end

  # Confirms the correct user.
  def correct_user
    @user = Event.find(params[:id]).user
    redirect_to(root_url) unless current_user == @user
  end

  # Confirms an admin user.
  def admin_user
    redirect_to(root_url) unless current_user && current_user.role == 'Admin'
  end
end