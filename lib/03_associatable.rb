require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    # ...
    class_name.constantize
  end

  def table_name
    # ...
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    # ...
    @foreign_key = options[:foreign_key] || (name.to_s.underscore + "_id").to_sym
    @class_name = options[:class_name] || (name.to_s.camelize)
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # ...
    @foreign_key = options[:foreign_key] || (self_class_name.to_s.underscore + "_id").to_sym
    @class_name = options[:class_name] || (name.to_s.singularize.to_s.camelize)
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # ...
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      table_name = options.table_name
      id = self.send("#{options.foreign_key}")

      res = DBConnection.execute(<<-SQL, id).first
        SELECT
          *
        FROM
          #{table_name}
        WHERE
          id = ?
      SQL

      return nil unless res
      options.model_class.new(res)
    end
  end

  def has_many(name, options = {})
    # ...
    options = HasManyOptions.new(name, self, options)

    define_method(name) do
      table_name = options.table_name
      id = self.send("#{options.primary_key}")
      res = DBConnection.execute(<<-SQL, id)
        SELECT
          *
        FROM
          #{table_name}
        WHERE
          #{options.foreign_key} = ?
      SQL

      res.map { |item| options.model_class.new(item) }
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @options ||= {}
    @options
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
