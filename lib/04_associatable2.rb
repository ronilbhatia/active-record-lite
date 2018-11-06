require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    # ...
    through_options = assoc_options[through_name]
    source_options = through_options.class_name.constantize.assoc_options[source_name]
    
    define_method(name) do
      source_table = source_options.table_name
      through_table = through_options.table_name

      id = self.send("#{through_options.foreign_key}")


      res = DBConnection.execute(<<-SQL, id).first
        SELECT
          #{source_table}.*
        FROM
          #{source_table}
          JOIN #{through_table} ON #{source_table}.id = #{through_table}.#{source_options.foreign_key}
        WHERE
          #{through_table}.id = ?
      SQL

      return nil unless res
      source_options.model_class.new(res)
    end
  end
end
