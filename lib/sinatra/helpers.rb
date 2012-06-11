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
      "/"
    end
  
    def login_url
      "/login"
    end
  
    def help_url
      "/help"
    end
    
    def log_url
      "/log"
    end
    
    def logs_url
      "/logs"
    end
    
    def preferences_url
      "/preferences"
    end
    
  end
  
  helpers Helpers
  
end
