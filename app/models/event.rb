class Event < ActiveRecord::Base
  extend SimpleCalendar
  include PgSearch
  belongs_to :user
  belongs_to :school
  has_calendar({:attribute => :event_start})
  has_many :claims, dependent: :destroy
  has_many :notifications, dependent: :destroy
  acts_as_taggable
  after_create :init
  #validates :user_id, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :event_start, :event_end, presence: true
  validates :title, length: {minimum: 2, maximum: 256},
            format: {with: /\A(\S+ )*\S+\z/i, 
                     message: "must be a valid alphanumeric string"}
  pg_search_scope :search_full_text, against: {
    title: 'A',
    content: 'B',
    event_start: 'B',
    #event_month: 'C',
    active: 'D',
    loc_id: 'D',
    user_id: 'D',
    user_name: 'A',
    loc_name: 'A',
  }

  def init
    self.update_attribute(:speaker_id, 0)
    self.update_attribute(:user_name, User.find(self.user_id).name)
    self.update_attribute(:loc_name, School.find(self.loc_id).school_name)
    self.update_attribute(:active, true)
    self.update_attribute(:complete, false)
  end

  def tag_list_commas
    self.tags.map(&:name).join(', ')
  end

  def event_month
    self.event_start.strftime('%B %Y')
  end
#TODO: Test get_pending_claims
  def get_pending_claims(user_id)
    filterDate(Event.joins(:claims).where('claims.user_id' => user_id)
      .where.not(speaker_id: user_id)
      .where(active: true)
      .where('claims.active' => true))
  end
#TODO: Test get_pending_events
  def get_pending_events(user_id)
    filterDate(Event.joins(:claims).where('events.user_id' => user_id).where('events.speaker_id'=> 0).where(active: true))
  end
#TODO: Test get_my_events
  def get_my_events(user_id)
    filterDate(Event.where("user_id = ? OR speaker_id = ?",  user_id, user_id).where(active: true))#speaker_id: current_user.id)
  end    

  def is_canceled
    not self.active and not self.complete
  end
#TODO: Test get_confirmed
  def get_confirmed(user_id)
    filterDate(Event.where("user_id = ? OR speaker_id = ?", user_id, user_id).where(active: true))
  end

  def filterDate(events)
    events.where("event_start > ?", Time.now)
  end

  def start()
    return self.event_start.in_time_zone(self.time_zone).strftime("%Y-%m-%d %l:%M %p %Z")
  end

  def end()
    self.event_end.in_time_zone(self.time_zone).strftime("%Y-%m-%d %l:%M %p %Z")
  end

  def date()
    self.event_end.in_time_zone(self.time_zone).strftime("%B %d, %Y")
  end

  def test()
    CompleteEventJob.set(queue: :default).perform_later()
  end

  def verify(key, value)
    case key
    when :event_start
      return String(self.start()) != value
    when :event_end
      return String(self.end()) != value
    else
      return String(self[key]) != value
    end
  end

  def handle_update()
    Claim.where(event_id: self.id,rejected:false).each do |x|
      Notification.create(user_id: x.user_id,
                        act_user_id: self.user_id,
                        event_id: self.id,
                        n_type: :event_update,
                        read: false)
      if User.find(x.user_id).set_updates
        # TODO UserMailer.send_update().deliver
        UserMailer.send_update(x.user_id, self.user_id, self.id).deliver_now
      end
    end
  end

  def cancel(current_id)
    puts "Cancel with user_id"
    if current_id == self.user_id
      self.update_attribute(:active, false)
      users = []
      if speaker_id == 0
        claims = Claim.where(event_id: self.id)
        claims.each do |c|
          users.append(c.user_id)
        end
      else 
        users.append(speaker_id)
      end
      users.each do |x|
        Notification.create(user_id: x,
                            act_user_id: current_id,
                            event_id: self.id,
                            n_type: :cancel,
                            read: false)
        UserMailer.event_cancel(x, current_id, self.id).deliver_now
      end
    end
  end
  
  def getSpeakerInfo()
    #Select the Claims from Claim table for this event
    @claims = Claim.where(event_id: self.id, confirmed_by_teacher:true)
   if @claims.exists?
    claimUserIdArr =  @claims.map {|i| i.user_id  }
     @users = User.select('id,name').where(:id => claimUserIdArr)
     if @users.exists?
       return @users
     else
        return "TBA"
     end
   else
     return "TBA"
    end
  end
  

  def jsonEvent(curr_user)
    school_name = nil
    user_name = nil
    if self.loc_id
      school_name = School.find(self.loc_id).school_name
    end
    if self.user_id
      user_name = User.find(self.user_id).name
    end
    result = self.attributes
    result[:event_start] = self.start()
    result[:event_end] = self.end()
    result[:user_name] = user_name
    result[:loc_name] = school_name
    result[:speaker] = getSpeakerInfo()
   # if self.speaker_id and self.speaker_id != 0
    #  result[:speaker] = User.find(self.speaker_id).name
    #else
     # result[:speaker] = "TBA"
    #end
    claim = Claim.where(event_id: self.id, user_id: curr_user)
    if claim.exists? and not claim[0].cancelled
      result[:claim_id] = claim[0].id
    else
      result[:claim_id] = 0
    end
    return result
  end

  def json_list_format
    {
      id: self.id,
      event_title: self.title,
      event_start: self.start()
    }
  end

  def pending_claims(params)
    #Claim list in event view page
    claims = Claim.where(event_id: self.id, confirmed_by_teacher:false, rejected:false)
              .paginate(page: params[:page])
    return claims.map{|c| c.json_list_format}
  end

  def present_time()
    s = self.event_start.in_time_zone(self.time_zone)
    e = self.event_end.in_time_zone(self.time_zone)
      return [s.strftime("%a"),s.strftime("%B"),(s.strftime("%d")).sub(/^0/, "")+",",s.strftime("%Y"),s.strftime("%l")+":"+s.strftime("%M"),
      "-",
      e.strftime("%l")+":"+e.strftime("%M"),e.strftime("%p")].join(" ")
  end
end
