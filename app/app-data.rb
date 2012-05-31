#require 'rdbi-driver-sqlite3'
require 'rubygems'
require 'java'
require 'jdbc/sqlite3'
require 'app/db'

org.sqlite.JDBC

class AppData

	def initialize
	  @@current_directory = Dir.getwd
		Dir.mkdir('data') unless File.directory?('data')
		
		#Connect to local sqlite3 database for preferences and local processing
		@db_local = DB.new :db => 'sqlite'

		@db_local.update_qry("create table if not exists items_to_break (item text)")
		@db_local.update_qry("create table if not exists items_to_weight (item text)")
		@db_local.update_qry("create table if not exists log (log_type char, log_code char, order_date date, customer text, ship_to text, item text, item_dsc text, cust_item text,created date)")
	end
	
	def maintenance(parms = {})
		puts "Maintenace type is: #{parms[:type]}"
		puts "Adding or Deleting? (A/D):"
		flag = gets.chomp.upcase
		case parms[:type]
			when "broken" then
				table = "items_to_break"
			when "weight" then
				table = "items_to_weight"
		end
		puts "Enter your items. Type X to quit:"
		input = gets.chomp.upcase
			while input != 'X'
				maintain(input,table,flag)
				puts "Enter your items. Type X to quit:"
				input = gets.chomp.upcase
			end
	end
	
	def maintain(input,tbl,flag)
		case flag
			when "A" then add_to_pref_table(input,tbl)
			when "D" then delete_from_pref_table(input,tbl)
		end
	end
	
	def get_items_to_break
		ary = @db_local.qry("select * from items_to_break")
		return ary
	end
	
	def get_items_weight_to_qty
		ary = @db_local.qry("select * from items_to_weight")
		return ary
	end
	
	def get_warnings(params = {})
		ary = @db_local.qry("select * from log where log_type = 'W' and order_date = params[:date]")
		return ary
	end
	
	def get_errors(params = {})
		ary = @db_local.qry("select * from log where log_type = 'E' and order_date = params[:date]")
		return ary
	end
	
	def item_to_break(candidate)
		rs = self.get_items_to_break
		#uom = ''
		unless rs.empty? 
			rs.each do |x|
				#if candidate.strip == x.item.to_s
				if candidate.strip == x['item']
					return 'EA'
				end
			end
		end
		return 'CS'		
	end
	
	def item_weight_to_qty(candidate, qty, weight)
		rs = self.get_items_weight_to_qty
		unless rs.empty?
			rs.each do |x|
				#if candidate.strip == x.item.to_s
				if candidate.strip == x['item']
					#new_qty = qty/(weight*100)
					new_qty = qty/(weight)
					puts "candidate = #{candidate}, qty = #{qty}, weight = #{weight}, new_qty = #{new_qty}"
					#if qty % (weight*100) > 0
					if qty % (weight) > 0
						new_qty += 1
					end
					qty = new_qty
				end
			end
		end			
		return qty
	end
	
	def log(parms = {})
	  values= "'#{parms[:type]}', '#{parms[:code]}', #{parms[:date]}, '#{parms[:cust]}', '#{parms[:ship]}', '#{parms[:cust_item]}', '#{parms[:item_dsc]}', #{Time.now.strftime("%F")}"
		
		self.add_to_log_table(values)
	end
	
	def close
	  @db_local.disconnect
	end
	
	protected
	def delete_from_pref_table(input,tbl)
		@db_local.update_qry("delete from #{tbl} where item = #{input.to_s}")
	end
	
	def add_to_pref_table(input,tbl)
		@db_local.update_qry("insert into #{tbl} (item) values(#{input.to_s})")
	end
	
	def add_to_log_table(input)
	  #puts "The SQL is: insert into log (log_type, log_code, order_date, customer, ship_to, cust_item, item_dsc, created) values(#{input})"
		@db_local.update_qry("insert into log (log_type, log_code, order_date, customer, ship_to, cust_item, item_dsc, created) values(#{input})")
	end
	
end
