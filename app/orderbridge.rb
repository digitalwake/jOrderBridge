require './app/order-processor.rb'
require './lib/sinatra/helpers.rb'
require './app/app-data.rb'
require 'sinatra/base'
require 'sinatra/flash'

class OrderBridge < Sinatra::Base

  helpers Sinatra::Helpers
  register Sinatra::Flash
  use Rack::MethodOverride

  #app = OrderProcessor.new
  #@app_data = AppData.new
  @@current_directory = Dir.getwd
  @@current_log_date = 0
  
  enable :sessions

  get "/" do
    #session['counter'] ||= 0
    #session['counter'] += 1
    erb :home
  end
  
  get "/download_advanced" do
    erb :download_advanced
  end
  
  get "/download" do
    erb :download
  end
  
  post "/download_advanced" do
    app = OrderProcessor.new
    success = false
    if params[:from_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/ and 
       params[:to_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/
       
      #puts "The from date was: #{params[:from_date]} and the to date was: #{params[:to_date]}"
            
      fromDateToCheck = Date.strptime(params[:from_date],'%m/%d/%Y')
      toDateToCheck = Date.strptime(params[:to_date],'%m/%d/%Y')
      
      #puts "fromDateToCheck = #{fromDateToCheck} and toDateToCheck = #{toDateToCheck}"
   
      if fromDateToCheck < toDateToCheck
      
        puts "Connecting and downloading orders"
        success = app.download :doe_user => params[:user],
                    :doe_pass => params[:pass],
                    :advanced => 'Y',
                    :date => params[:from_date],
                    :end_date => params[:to_date],
                    :boro => ""
                    
        if success == true
          erb :download_success
        else
          erb :failure
        end
      end
    end
  end
  
  post "/download" do
    app = OrderProcessor.new
    success = false
    puts "Connecting and downloading orders"
    #Check for proper date format (mm/dd/yyyy)
    if params[:date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/
      success = app.download :doe_user => params[:user],
                    :doe_pass => params[:pass],
                    :advanced => 'N',
                    :lock => params[:lock],
                    :date => params[:date]
                    
      if success == true
        erb :download_success
      end
    end
  end
  
  get "/process_file" do
    erb :process_file
  end
  
  post "/process_file_current" do
    app = OrderProcessor.new
    params[:advanced] ='N'
    success = app.process_download(params)
    if success == true
      erb :success
    else
      erb :failure
    end
  end
  
   post "/process_file_advanced" do
    app = OrderProcessor.new
    params[:advanced] ='Y'
    success = app.process_download(params)
    if success == true
      erb :success
    else
      erb :failure
    end
  end
  
  get "/advanced" do
    erb :advanced
  end
  
  post "/advanced" do
    puts "post/advanced"
    app = OrderProcessor.new
    success = false
    if params[:from_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/ and 
       params[:to_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/
       
      #puts "The from date was: #{params[:from_date]} and the to date was: #{params[:to_date]}"
            
      fromDateToCheck = Date.strptime(params[:from_date],'%m/%d/%Y')
      toDateToCheck = Date.strptime(params[:to_date],'%m/%d/%Y')
      
      #puts "fromDateToCheck = #{fromDateToCheck} and toDateToCheck = #{toDateToCheck}"
   
      if fromDateToCheck < toDateToCheck
       
        puts "Connecting and downloading orders"
        success = app.prepare :doe_user => params[:user],
                    :doe_pass => params[:pass],
                    :advanced => 'Y',
                    :date => params[:from_date],
                    :end_date => params[:to_date],
                    :boro => ""
                    
        if success == true
          puts "Processing Advanced orders and uploading to S2K"
          success = app.process
          puts "Closing connections"
          flash[:notice] = app.close
          puts "Processing complete"
        end
        if success
          redirect to '/success' 
        else
          redirect to '/fail'
        end
      else
        erb :invalid_date
      end
    end
  end
  
  get "/current" do
    erb :current
  end
  
  post "/current" do
    app = OrderProcessor.new
    success = false
    puts "Connecting and downloading orders"
    #Check for proper date format (mm/dd/yyyy)
    if params[:date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/
      success = app.prepare :doe_user => params[:user],
                    :doe_pass => params[:pass],
                    :advanced => 'N',
                    :lock => params[:lock],
                    :date => params[:date]
                    
      if success == true
        puts "Processing Current orders and uploading to S2K"
        success = app.process
        puts "Closing connections"
        flash[:notice] = app.close
        puts "Processing complete"
      end
      if success
        redirect to '/success' 
      else
        redirect to '/fail'
      end
    
    else
      erb :invalid_date
    end
  end
  
  get "/success" do
    erb :success
  end
  
  get "/fail" do
    erb :failure
  end
  
  get "/logs" do
    erb :logs
  end
  
  post "/log" do
    if params[:from_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/ and
        params[:to_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/ and
        params[:run_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/
      @from_date = params[:from_date][6..9].to_s + params[:from_date][0..1].to_s + params[:from_date][3..4].to_s
      @to_date = params[:to_date][6..9].to_s + params[:to_date][0..1].to_s + params[:to_date][3..4].to_s
      @order_type = params[:ord_type]
      @run_date = params[:run_date][6..9].to_s + "-" + params[:run_date][0..1].to_s + "-" + params[:run_date][3..4].to_s
      app_data = AppData.new
#     id = app_data.run_id?
      puts "The Current Run_date is: #{@run_date}"
      puts ""
      puts "From Date is: #{@from_date}"
      puts "To Date is: #{@to_date}"
      puts ""
      if params[:log_type] == 'E'
        @log_type = 'errors'
        @data = app_data.get_errors :from_date => @from_date,
                                  :to_date => @to_date,
                                  :ord_type => @order_type, :run_date => @run_date 
        #@data = @app.get_data.get_errors :date => @date
        app_data.close
        unless @data.empty?
          erb :log
        else
          erb :log_empty
        end
        #redirect "/log/errors/#{date_url}"
      else
        @log_type = 'warnings'
        @data = app_data.get_warnings :from_date => @from_date,
                                    :to_date => @to_date,
                                    :ord_type => params[:ord_type], :run_date => @run_date
        #@data = @app.get_data.get_warnings :date => @date
        app_data.close
        unless @data.empty?
          erb :log
        else
          erb :log_empty
        end
        #redirect "/log/warnings/#{date_url}"
      end
    else
      #bad date format
      erb :invalid_date
    end
  end
  
  #post "/log/:log_type/:order_type/:date/:item" do
  get "/log-details?" do
    app_data = AppData.new
    puts "Item paramter = #{params[:item].gsub(/\+/," ")}"
    @run_date = params[:run_date]
    puts "The Current Run_date is: #{@run_date}"
    if params[:log_type] == 'errors'
      @log_type = 'errors'
      @data = app_data.get_error_orders_for_item :date => params[:order_date],
                                                 :run_date => @run_date,
                                                 :item => params[:item].gsub(/\+/," "),
                                                 :ord_type => params[:order_type]
      #@data = @app.get_data.get_error_orders_for_item :date => params[:date], :item => params[:item]
    else
      @log_type = 'warnings'
      @data = app_data.get_warning_orders_for_item :date => params[:order_date],
                                                 :run_date => @run_date,
                                                 :item => params[:item].gsub(/\+/," "),
                                                 :ord_type => params[:order_type]
      #@data = @app.get_data.get_warning_orders_for_item :date => params[:date], :item => params[:item]
    end
    app_data.close
    unless @data.empty?
      erb :log_details
    else
      erb :log_empty
    end
  end
  
  get "/preferences" do
    erb :preferences
  end
  
  get "/items-to-break" do
    app_data = AppData.new
    @data = app_data.get_items_to_break
    app_data.close
    #unless @data.empty?
    #  erb :items_to_break
    #else
    #  erb :log_empty
    #end
   erb :items_to_break
  end
  
  get "/weight-to-case" do
    app_data = AppData.new
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #unless @data.empty?
    #  erb :weight_to_cases
    #else
    # erb :log_empty
    #end
    erb :weight_to_cases
  end
  
  post "/items-to-break" do
    app_data = AppData.new
    puts "Item to break = #{params[:item]} and Description = #{params[:desc]}"
    app_data.maintain "items_to_break", 'A', :item => params[:item], :desc => params[:desc]
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #erb :items_to_break
    redirect to "/items-to-break"
  end
  
  post "/weight-to-case" do
    app_data = AppData.new
     app_data.maintain "weight_to_cases", 'A', :item => params[:item], :desc => params[:desc]
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #erb :weight_to_cases
    redirect to "/weight-to-case"
  end
  
  delete "/items-to-break" do
    app_data = AppData.new
    puts "Item to break = #{params[:item]} and Description = #{params[:desc]}"
    app_data.maintain "items_to_break", 'D', :item => params[:item], :desc => params[:desc]
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #erb :items_to_break
    redirect to "/items-to-break"
  end
  
  delete "/weight-to-case" do
    app_data = AppData.new
    app_data.maintain "weight_to_cases", 'D', :item => params[:item], :desc => params[:desc]
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #erb :weight_to_cases
    redirect to "/weight-to-case"
  end
  
  get "/restrictions" do
    app_data = AppData.new
    @data = app_data.get_restricted_items
    app_data.close
    unless @data.empty?
      erb :restrictions
    else
      erb :no_prefs_restrictions
    end
  end
  
  get "/authorizations" do
    app_data = AppData.new
    @data = app_data.get_authorized_customers
    app_data.close
    unless @data.empty?
      erb :authorizations
    else
     erb :no_prefs_authorizations
    end
  end
  
  post "/authorizations" do
    app_data = AppData.new
    puts "Authorized Customer = #{params[:customer]}"
    app_data.maintain "authorizations", 'A', :customer => params[:customer]
    @data = app_data.get_authorized_customers
    app_data.close
    #erb :items_to_break
    redirect to "/authorizations"
  end
  
  post "/restrictions" do
    app_data = AppData.new
    puts "Restricted Item = #{params[:item]}"
    app_data.maintain "restricted_items", 'A', :item => params[:item]
    @data = app_data.get_restricted_items
    app_data.close
    #erb :items_to_break
    redirect to "/restrictions"
  end
  
  delete "/authorizations" do
    app_data = AppData.new
    app_data.maintain "authorizations", 'D', :customer => params[:customer]
    @data = app_data.get_authorized_customers
    app_data.close
    #erb :weight_to_cases
    redirect to "/authorizations"
  end
  
  delete "/restrictions" do
    app_data = AppData.new
    app_data.maintain "restricted_items", 'D', :item => params[:item]
    @data = app_data.get_restricted_items
    app_data.close
    #erb :weight_to_cases
    redirect to "/restrictions"
  end

end

