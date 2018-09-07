require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    if @columns.nil?
      result = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{self.table_name}
        LIMIT
          0
      SQL
      @columns = result.first.map(&:to_sym)
    else
      @columns
    end
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end
      define_method("#{column}=") do |value|
        self.attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM
        #{table_name}
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map { |item| self.new(item) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    return nil if result.length == 0
    self.new(result.first)
  end

  def initialize(params = {})
    params.each do |name, value|
      raise "unknown attribute '#{name}'" unless self.class.columns.include?(name.to_sym)
      self.send("#{name.to_sym}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    cols = self.class.columns[1..-1]
    id = self.class.columns.first
    col_names = cols.map(&:to_s).join(", ")
    col_values = attribute_values[1..-1]
    question_marks = (["?"] * cols.length).join(", ")
    DBConnection.execute(<<-SQL, *col_values )
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.send("#{id}=", DBConnection.last_insert_row_id)
  end

  def update
    cols = self.class.columns[1..-1]
    id_col = self.class.columns.first
    set_values = cols.map { |col| "#{col.to_sym} = ?" }.join(", ")
    col_values = attribute_values.drop(1) + attribute_values.take(1)
    DBConnection.execute(<<-SQL, *col_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_values}
      WHERE
        id = ?
    SQL
  end

  def save
    if self.send(self.class.columns.first)
      self.update
    else
      self.insert
    end
  end
end
