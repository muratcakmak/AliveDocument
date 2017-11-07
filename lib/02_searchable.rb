require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = ""
    params.keys.each_with_index do |key, index|
      if params.length - 1 == index
        where_line += "#{key} = '#{params[key]}'"
      else
        where_line += "#{key} = '#{params[key]}' AND "
      end
    end

    data = DBConnection.execute(<<-SQL)
    SELECT
       *
    FROM
      #{self.table_name}
    WHERE
      #{where_line}
    SQL
    data.map! do |datum|
      self.new(datum)
    end
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
