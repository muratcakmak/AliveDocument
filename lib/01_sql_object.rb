require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL).first.map {|el| el.to_sym}
    SELECT
    *
    FROM
    #{self.table_name}
    SQL
  end

  def self.finalize!
    self.columns.each do |column|
      define_method("#{column}") do
        attributes["#{column}".to_sym]
      end

      define_method("#{column}=") do |val|
        attributes["#{column}".to_sym] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    self.table_name = "#{self}".tableize unless @table_name
    @table_name
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT
    *
    FROM
    #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    res = []
    results.each do |dict|
      res << self.new(dict)
    end
    res
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
    SELECT
    *
    FROM
    #{table_name}
    WHERE
    id=#{id}
    SQL
    result = parse_all(result).first
    result ? result : nil
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=", params[attr_name])
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |attr_name|
      self.send(attr_name)
    end
  end

  def insert
    col_names = self.class.columns.drop(1).join(", ")
    question_marks = (['?'] * (self.class.columns.count - 1)).join(',')
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns.drop(1).join(" =?, ") + " =?"
    debugger
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      id = #{self.id}
    SQL
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end
