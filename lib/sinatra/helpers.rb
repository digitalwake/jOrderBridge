require 'sinatra/base'

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
  end
  
  helpers Helpers
  
end
