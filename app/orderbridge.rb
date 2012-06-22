require 'app/order-processor.rb'
require 'lib/sinatra/helpers.rb'
require 'app/app-data.rb'
require 'sinatra/base'

class OrderBridge < Sinatra::Base

  helpers Sinatra::Helpers
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
  
  get "/advanced" do
    erb :advanced
  end
  
  post "/advanced" do
    app = OrderProcessor.new
    success = false
    fdate = params[:from_date][0..1].to_s + params[:from_date][3..4].to_s + params[:from_date][6..9].to_s
    tdate = params[:to_date][0..1].to_s + params[:to_date][3..4].to_s + params[:to_date][6..9].to_s
    puts "The form has posted."
    puts "The from date was: #{params[:from_date]} and the to date was: #{params[:to_date]}
          fdate = #{fdate} and tdate = #{tdate}"
    if params[:from_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/ and 
       params[:to_date] =~ /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/ and
       fdate.to_i < tdate.to_i
       
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
        app.close
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
        app.close
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
    @date = params[:date][6..9].to_s + params[:date][0..1].to_s + params[:date][3..4].to_s
    @order_type = params[:ord_type]
    app_data = AppData.new
    if params[:log_type] == 'E'
      @log_type = 'errors'
      @data = app_data.get_errors :date => @date, :ord_type => @order_type 
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
      @data = app_data.get_warnings :date => @date, :ord_type => params[:ord_type]
      #@data = @app.get_data.get_warnings :date => @date
      app_data.close
      unless @data.empty?
        erb :log
      else
        erb :log_empty
      end
      #redirect "/log/warnings/#{date_url}"
    end
  end
  
  #post "/log/:log_type/:order_type/:date/:item" do
  get "/log-details?" do
    app_data = AppData.new
    puts "Item paramter = #{params[:item].gsub(/\+/," ")}"
    if params[:log_type] == 'E'
      @log_type = 'errors'
      @data = app_data.get_error_orders_for_item :date => params[:order_date],
                                                 :item => params[:item].gsub(/\+/," "),
                                                 :ord_type => params[:order_type]
      #@data = @app.get_data.get_error_orders_for_item :date => params[:date], :item => params[:item]
    else
      @log_type = 'warnings'
      @data = app_data.get_warning_orders_for_item :date => params[:order_date],
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
    unless @data.empty?
      erb :items_to_break
    else
      erb :log_empty
    end
  end
  
  get "/weight-to-case" do
    app_data = AppData.new
    @data = app_data.get_items_weight_to_qty
    app_data.close
    unless @data.empty?
      erb :weight_to_cases
    else
      erb :log_empty
    end
  end
  
  post "/items-to-break" do
    app_data = AppData.new
    app_data.maintain params[:item], "items_to_break", 'A'
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #erb :items_to_break
    redirect to "/items-to-break"
  end
  
  post "/weight-to-case" do
    app_data = AppData.new
    app_data.maintain params[:item], "weight_to_cases", 'A'
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #erb :weight_to_cases
    redirect to "/weight-to-case"
  end
  
  delete "/items-to-break" do
    app_data = AppData.new
    app_data.maintain params[:item], "items_to_break", 'D'
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #erb :items_to_break
    redirect to "/items-to-break"
  end
  
  delete "/weight-to-case" do
    app_data = AppData.new
    app_data.maintain params[:item], "weight_to_cases", 'D'
    @data = app_data.get_items_weight_to_qty
    app_data.close
    #erb :weight_to_cases
    redirect to "/weight-to-case"
  end

end

