require 'rubygems'
require 'savon'

class DoeOrders

@@current_log_file = "tmp/current_orders_#{Time.now.strftime("%Y%m%d.xml")}"
@@advanced_log_file = "tmp/advanced_orders_#{Time.now.strftime("%Y%m%d.xml")}"
@@wsdl_info = "tmp/info.txt"

	def initialize
		Dir.mkdir('./tmp') unless File.directory?('./tmp')
		@vendor_id = ""
		@pass = ""
		@date = ""
		@end_date = ""
		@locked_flag = false
		@boro = ""
		#@cfh = File.open(@@current_log_file, "w")
		@afh = File.open(@@advanced_log_file, "w")
	end

	def get_order_filename
		return @@current_log_file
	end

	def get_advanced_order_filename
		return @@advanced_log_file
	end

	attr_accessor :vendor_id, :pass, :date, :end_date, :locked_flag, :boro

	def get_current_orders
		client = Savon::Client.new do 
		wsdl.document = "http://www.opt-osfns.org/osfns/resources/sfordering/SFWebService.asmx?WSDL"
		end
		
		File.open(@@wsdl_info,"w") do |f|
			f.puts "WSDL query started at #{Time.now}"
			f.puts client.wsdl.namespace
			f.puts client.wsdl.endpoint
			f.puts client.wsdl.soap_actions
		end

		response = client.request :get_orders_xml_all_boros do
			soap.version = 2
			if locked_flag == true
				soap.input = ["GetOrdersXMLAllBorosFinal", {"xmlns" => "http://www.opt-osfns.org/"}]
				puts "GetOrdersXMLAllBorosFinal called. (LOCKED)"
			else
				soap.input = ["GetOrdersXMLAllBoros", {"xmlns" => "http://www.opt-osfns.org/"}]
				puts "GetOrdersXMLAllBoros called. (NOT locked)"
			end
			soap.body = {
				"vendorId" => self.vendor_id,
				"pwd"      => self.pass,
				"deliveryDate" => self.date,
			}
			soap.element_form_default = :unqualified
			soap.namespaces = {
				"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
				"xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
				"xmlns:soap12" => "http://www.w3.org/2003/05/soap-envelope"
			}
			soap.env_namespace = 'soap12'
		end

		#File.new(@@current_log_file) unless File.exists?(@@current_log_file)
		#File.open(@@current_log_file,"w") do |f|
			#f.puts "Started at #{Time.now} Order Lock = #{:locked_flag}"
			#f.puts response.http
			#f.puts response.to_xml
		#end
		@cfh.puts response.to_xml
		@cfh.close
		return response.to_xml
	end
	
	def get_advanced_orders
		client = Savon::Client.new do 
		wsdl.document = "http://www.opt-osfns.org/osfns/resources/sfordering/SFWebService.asmx?WSDL"
		end

		File.open(@@wsdl_info,'w') do |f|
			f.puts "WSDL query started at #{Time.now}"
			#f.prints "Namespace: "
			f.puts client.wsdl.namespace
			#f.prints "Endpoint: "
			f.puts client.wsdl.endpoint
			#f.prints "Actions: "
			f.puts client.wsdl.soap_actions
		end

		response = client.request :get_orders_date_range_xml do
			soap.version = 2
			soap.input = ["GetOrdersDateRangeXML", {"xmlns" => "http://www.opt-osfns.org/"}]
			soap.body = {
				"vendorId" => self.vendor_id,
				"pwd"      => self.pass,
				"startDate" => self.date,
				"endDate" => self.end_date,
				"boro" => self.boro
			}
			soap.element_form_default = :unqualified
			soap.namespaces = {
				"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
				"xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
				"xmlns:soap12" => "http://www.w3.org/2003/05/soap-envelope"
			}
			soap.env_namespace = 'soap12'
		end

		#File.open(@@advanced_log_file,'w') do |f|
			#f.puts "test started at #{Time.now}"
			#f.puts response.http
			#f.puts response.to_xml
		#end
		@afh.puts response.to_xml
		@afh.close
		return response.to_xml
	end
end
