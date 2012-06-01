require 'app/order-processor.rb'
require 'lib/sinatra/helpers.rb'
require 'sinatra/base'

class OrderBridge < Sinatra::Base

helpers Sinatra::Helpers
	
app = OrderProcessor.new
log_viewer = app.get_log
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
    success = false
    puts "The form has posted."
    puts "The date was: #{params[:date]}"
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
    if params[:log_type] == 'E'
      @log_type = 'errors'
      @data = log_viewer.get_errors :date => @date 
      erb :log
      #redirect "/log/errors/#{date_url}"
    else
      @log_type = 'warnings'
      @data = log_viewer.get_warnings :date => @date 
      erb :log
      #redirect "/log/warnings/#{date_url}"
    end
  end
  
  get "/log/:log_type/:date/:item" do
    if params[:log_type] == 'errors'
      @log_type = 'errors'
      @data = log_viewer.get_error_orders_for_item :date => params[:date], :item => params[:item]
    else
      @log_type = 'warnings'
      @data = log_viewer.get_warning_orders_for_item :date => params[:date], :item => params[:item]
    end
    
    erb :log_details
  end
  
  get "/preferences" do
    erb :home
  end

end

