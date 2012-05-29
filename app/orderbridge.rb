require 'app/order-processor.rb'
require 'lib/sinatra/helpers.rb'
require 'sinatra/base'

class OrderBridge < Sinatra::Base

helpers Sinatra::Helpers
	
session = OrderProcessor.new
@@current_directory = Dir.getwd

  get "/" do
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
    session.prepare :doe_user => params[:user],
                    :doe_pass => params[:pass],
                    :advanced => 'Y',
                    :date => params[:from_date],
                    :end_date => params[:to_date]
                    
    puts "Processing orders and uploading to S2K"
    success = session.process
    puts "Closing connections"
    session.close
    puts "Processing complete"
    
    if success
      #change this to a redirect
      erb :success 
    else
      erb :fail
    end
  end
  
  get "/current" do
    erb :current
  end

end

