require 'java'
require 'lib/jt400-6.1'
require 'date'
require 'bigdecimal'

java_import 'com.ibm.as400.access.AS400JDBCDriver'

@@library_prefix="R37"

class DB
	def initialize(parms = {})
	  @@current_directory = Dir.getwd
	  if parms[:db] == 'as400'
	    begin
	   	  @connection ||= java.sql.DriverManager.get_connection "jdbc:as400://S2K/",parms[:user], parms[:pass]
	   	rescue java.sql.SQLException
	   	  puts "Error connection to iSeries. Error code: #{SQLException.getErrorCode()}
	   	        SQL State: #{java.sql.SQLException.getSQLState()}."
	   	end
	   	  
  	  #rs = @connection.createStatement.executeQuery("SELECT EHCMP,EHTYPE,EHCUST,EHPONO,EHSHIP,EHDDT8 FROM t37files.vedxpohw")
  	  #return rs_to_hash(rs) #.inspect
		 else
		   begin
		     @connection ||= java.sql.DriverManager.getConnection "jdbc:sqlite:#{@@current_directory}/data/orderbridge.sqlite3"
		   rescue SQLException
	   	   puts "Error connection to iSeries. Error code: #{SQLException.getErrorCode()}
	   	        SQL State: #{SQLException.getSQLState()}."
	   	 end
		 end
		 @stmt = @connection.createStatement
	end

	def qry(sql)
		temp = @stmt.executeQuery(sql)
		rs = self.rs_to_hash(temp)
		return rs
	end
	
	def update_qry(sql)
		@stmt.executeUpdate(sql)
	end
	
	def rs_to_hash(resultset)
  	meta = resultset.meta_data
  	rows = []

  	while resultset.next
    	row = {}

    	(1..meta.column_count).each do |i|
      	name = meta.column_name i
      	row[name]  =  case meta.column_type(i)
                    when -6, -5, 5, 4
                      # TINYINT, BIGINT, INTEGER
                      resultset.get_int(i).to_i
                    when 41
                      # Date
                      resultset.get_date(i)
                    when 92
                      # Time
                      resultset.get_time(i).to_i
                    when 93
                      # Timestamp
                      resultset.get_timestamp(i)
                    when 2, 3, 6
                      # NUMERIC, DECIMAL, FLOAT
                      case meta.scale(i)
                      when 0
                        resultset.get_long(i).to_i
                      else
                        BigDecimal.new(resultset.get_string(i).to_s)
                      end
                    when 1, -15, -9, 12
                      # CHAR, NCHAR, NVARCHAR, VARCHAR
                      resultset.get_string(i).to_s
                    else
                      resultset.get_string(i).to_s
                    end
    	end

    	rows << row
  	end
  	rows
	end
	
	def close
	  @stmt.close
	  @connection.close
	  @connection.finalize
	end
	
	
	def disconnect
	  @stmt.close
	  @connection.close
	  @connection.finalize
	end
end
