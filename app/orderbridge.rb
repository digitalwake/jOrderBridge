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
    puts "The form has posted."
    puts "The from date was: #{params[:from_date]} and the to date was: #{params[:to_date]}"
    puts "Connecting and downloading orders"
    app.prepare :doe_user => params[:user],
                    :doe_pass => params[:pass],
                    :advanced => 'Y',
                    :date => params[:from_date],
                    :end_date => params[:to_date]
                    
    puts "Processing orders and uploading to S2K"
    success = app.process
    puts "Closing connections"
    app.close
    puts "Processing complete"
    
    if success
      #change this to a redirect
      redirect '/success' 
    else
      redirect '/fail'
    end
  end
  
  get "/current" do
    erb :current
  end
  
  post "/current" do
    app = OrderProcessor.new
    success = false
    puts "Connecting and downloading orders"
    app.prepare :doe_user => params[:user],
                    :doe_pass => params[:pass],
                    :advanced => 'N',
                    :lock => 'N',
                    :date => params[:date]
                    
    puts "Processing orders and uploading to S2K"
    success = app.process
    puts "Closing connections"
    app.close
    puts "Processing complete"
    
    if success
      #change this to a redirect
      redirect '/success' 
    else
      redirect '/fail'
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
    @date = "#{params[:date].slice!(6..9)}#{params[:date].slice!(0..1)}#{params[:date].slice!(1..2)}"
    app_data = AppData.new
    if params[:log_type] == 'E'
      @log_type = 'errors'
      @data = app_data.get_errors :date => @date 
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
      @data = app_data.get_warnings :date => @date
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
  
  get "/log/:log_type/:date/:item" do
    app_data = AppData.new
    if params[:log_type] == 'errors'
      @log_type = 'errors'
      @data = app_data.get_error_orders_for_item :date => params[:date], :item => params[:item]
      #@data = @app.get_data.get_error_orders_for_item :date => params[:date], :item => params[:item]
    else
      @log_type = 'warnings'
      @data = app_data.get_warning_orders_for_item :date => params[:date], :item => params[:item]
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
    erb :items_to_break
  end
  
  post "/weight-to-case" do
    app_data = AppData.new
    app_data.maintain params[:item], "weight_to_cases", 'A'
    @data = app_data.get_items_weight_to_qty
    app_data.close
    erb :weight_to_cases
  end
  
  delete "/items-to-break" do
    app_data = AppData.new
    app_data.maintain params[:item], "items_to_break", 'D'
    @data = app_data.get_items_weight_to_qty
    app_data.close
    erb :items_to_break
  end
  
  delete "/weight-to-case" do
    app_data = AppData.new
    app_data.maintain params[:item], "weight_to_cases", 'D'
    @data = app_data.get_items_weight_to_qty
    app_data.close
    erb :weight_to_cases
  end

end

