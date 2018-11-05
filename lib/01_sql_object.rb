require_relative 'db_connection'
require 'byebug'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    return @columns if @columns
    columns = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
      LIMIT
        0
    SQL

    @columns = columns.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |new_name|
        attributes[column] = new_name
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name || self.to_s.tableize
  end

  def self.all
    # ...
    items = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    
    parse_all(items)
  end

  def self.parse_all(results)
    # ...
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    # ...
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL

    return nil if result.empty?
    self.new(result.first)
  end

  def initialize(params = {})
    # ...
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    attributes.values
  end

  def insert
    # ...
    cols = self.class.columns
    col_string = cols[1..-1].join(", ")
    question_string = cols[1..-1].map { "?" }.join(", ")
    res = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_string})
      VALUES
        (#{question_string})
    SQL

    self.id = DBConnection.last_insert_row_id
    self
  end

  def update
    # ...
    cols = self.class.columns
    col_string = cols[1..-1].map { |col| "#{col} = ?" }.join(", ")
    res = DBConnection.execute(<<-SQL, *attribute_values[1..-1], id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_string}
      WHERE
        id = ?
    SQL
  end

  def save
    # ...
    id.nil? ? insert : update
  end
end
