require 'sinatra/base'
require 'app/app-data.rb'

module Sinatra
  module Helpers
  
    def link_to(url,text=url,opts={})
      attributes = ""
     opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
     "<a href=\"#{url}\" #{attributes}>#{text}</a>"
    end
  
    def home_url
      url '/'
    end
  
    def login_url
      url '/login'
    end
  
    def help_url
      url '/help'
    end
    
    def log_url
      url '/log'
    end
    
    def logs_url
      url '/logs'
    end
    
    def log_details_url
      url '/log-details'
    end
    
    def preferences_url
      url '/preferences'
    end
    
    def advanced_orders_url
      url '/advanced'
    end
    
    def current_orders_url
      url '/current'
    end
    
  end
  
  helpers Helpers
  
end
