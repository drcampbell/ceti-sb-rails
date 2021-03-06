require 'csv'
class AdminController < ApplicationController
  before_action :admin_user
  def index
    if params != nil
      @header_array = []
      date_search
    end
    respond_to do |format|
        format.html # index.html.erb
        #format.json { render json: list_events(@events).as_json }
        format.csv do
          headers['Content-Disposition'] = "attachment; filename=\"Event-list.csv\""
          headers['Content-Type'] ||= 'text/csv'
        end

    end
  end
  def date_search
    
    fdate = "1999-01-01 "
    tdate = Time.now.strftime("%Y/%m/%d ")
    if params != nil && params[:fdate] == "" && params[:tdate] == ""
       #fromdate = '2016-05-05 07:37:49.228131'
       #todate = '2016-06-05 07:37:49.228131'
      # params[:fdate] = "-05-05 07:37:49.228131"
      # params[:tdate] = "2017-03-21 07:37:49.228131"
      fdate = "1999-01-01 12:00"
      tdate = Time.now.strftime("%Y/%m/%d %H:%M")

         
      if params[:commit] == "Summary View"
        puts "Summary View"
         @data = SearchService.new.date_search_db(fdate, tdate)
         @header_array << 'Schools Name'
         @header_array << 'Events Created' 
         @header_array << 'Events Claimed'
         @header_array << 'No of Awarded Badges'
      
      else if params[:commit] == "Detailed View"
        puts "Detailed View"
          @data = SearchService.new.detailed_view(fdate, tdate)
        
         
         @header_array << 'Start Date'
         @header_array << 'End Date' 
         @header_array << 'Schools Name'
         @header_array << 'Event Title'
         @header_array << 'Events Content'
         @header_array << 'Speaker'
         @header_array << 'Badge Awarded?'
      end
      end
        
    else if params != nil && (params[:fdate] != nil && params[:tdate] != nil)
      if params[:fdate] != "" 
        fdate = params[:fdate]
       end
       if params[:tdate] != ""
        tdate = params[:tdate]
       end
       if params[:format] != "csv" then
         fdate = fdate << " 12:00:00.0000"
         tdate = tdate << " 12:00:00.0000"
       end
       
         
          
      if params[:commit] == "Summary View"
        puts "Summary View"
        @data = SearchService.new.date_search_db(fdate, tdate)
         @header_array << 'School Name'
         @header_array << 'Events Created' 
         @header_array << 'Events Claimed'
         @header_array << 'No of Awarded Badges'
       
        else if params[:commit] == "Detailed View"
        puts "Detailed View"
         @data = SearchService.new.detailed_view(fdate, tdate)
        
         
         @header_array << 'Start Date'
         @header_array << 'End Date' 
         @header_array << 'School Name'
         @header_array << 'Event Title'
         @header_array << 'Event Content'
         @header_array << 'Speaker'
         @header_array << 'Badge Awarded?'
         
        end
      end
    
    end
    end
 end
 def admin_user
    redirect_to(root_url) unless current_user && current_user.admin?
  end
 end
  
