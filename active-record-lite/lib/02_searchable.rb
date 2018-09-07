require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map{ |col| "#{col} = ?"}.join(" AND ")
    col_values = params.values
    results = DBConnection.execute(<<-SQL, *col_values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    return [] if results.length == 0
    results.map { |row| self.new(row) }
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
