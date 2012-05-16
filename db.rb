require 'java'
require 'jt400-6.1'
require 'date'
require 'bigdecimal'

java_import 'com.ibm.as400.access.AS400JDBCDriver'

@@library_prefix="T37"

class DB
	def initialize(user, pass)
  	@connection ||= java.sql.DriverManager.get_connection("jdbc:as400://S2K/",user, pass)
  	#rs = @connection.createStatement.executeQuery("SELECT EHCMP,EHTYPE,EHCUST,EHPONO,EHSHIP,EHDDT8 FROM t37files.vedxpohw")
  	#return rs_to_hash(rs) #.inspect
		@stmt = @connection.createStatement
	end

	def qry(sql)
		temp = @stmt.executeQuery(sql)
		rs = self.rs_to_hash(temp)
		#@stmt.close
		return rs
	end
	
	def clear_edi(lib)
	  @stmt ||= @connection.createStatement
	  @stmt.executeUpdate("delete from #{lib}files.vedxpohw")
		@stmt.executeUpdate("delete from #{lib}files.vedxpodh")
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
	
	def disconnect
	  @stmt.finish
	  @connection.close
	 end
end
