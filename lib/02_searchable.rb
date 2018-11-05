require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # ...
    query_string = params.map { |k, _| "#{k} = ?" }.join(" AND ")

    res = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{query_string}
    SQL

    parse_all(res)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
