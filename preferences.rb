#require 'rdbi-driver-sqlite3'
require 'rubygems'
require 'jdbc/sqlite3'
require 'java'
require 'db'

org.sqlite.JDBC

class Preferences

	def initialize
		Dir.mkdir('./data') unless File.directory?('./data')
		#Database.new('./data/orderbridge.sqlite3') unless File.exists?('./data/orderbridge.sqlite3')
		
		#Connect to local sqlite3 database for preferences and local processing
		#@db_local = RDBI.connect(RDBI::Driver::SQLite3, :database => './data/orderbridge.sqlite3')
		@db_local = java.sql.DriverManager.getConnection 'jdbc:sqlite:./data/orderbridge.sqlite3'

		#if @db_local.connected
			#puts "We're connected to SQLite3"
			#@db_local.execute("create table if not exists items_to_break (item string)")
			#@db_local.execute("create table if not exists items_to_weight (item string)")
		#else
			#puts "We're not connected to SQLite3"
		#end
		@stmt = @db_local.createStatement
		@stmt.executeUpdate("create table if not exists items_to_break (item string)")
		@stmt.executeUpdate("create table if not exists items_to_weight (item string)")
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
		#rs = @db_local.execute("select * from items_to_break").fetch(:all,:Struct)
		#return rs
		rs = @stmt.execute("select * from items_to_break")
		return DB.rs_to_hash(rs)
	end
	
	def get_items_weight_to_qty
		#rs = @db_local.execute("select * from items_to_weight").fetch(:all,:Struct)
		#return rs
		#return rs
		rs = @stmt.executeQuery("select * from items_to_weight")
		return DB.rs_to_hash(rs)
	end
	
	def item_to_break(candidate)
		rs = self.get_items_to_break
		#uom = ''
		unless rs.empty? 
			rs.each do |x|
				#if candidate.strip == x.item.to_s
				if candidate.strip == x[:item]
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
				if candidate.strip == x[:item]
					#new_qty = qty/(weight*100)
					new_qty = qty/(weight)
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
	
	protected
	def delete_from_pref_table(input,tbl)
		@stmt.executeUpdate("delete from #{tbl} where item = #{input}")
	end
	
	def add_to_pref_table(input,tbl)
		@stmt.executeUpdate("insert into #{tbl} (item) values(#{input})")
	end
	
end
