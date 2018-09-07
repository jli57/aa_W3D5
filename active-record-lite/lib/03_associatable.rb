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
    @class_name.constantize
  end

  def table_name
    @class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = {
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.singularize.camelcase
    }
    default.merge!(options)

    default.each do |name, val|
      self.send("#{name}=", val)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default = {
      foreign_key: "#{self_class_name.downcase.singularize}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.singularize.camelcase
    }
    default.merge!(options)

    default.each do |name, val|
      self.send("#{name}=", val)
    end

    @table_name = self_class_name
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    assoc = BelongsToOptions.new(name, options)

    define_method(name) do
      fk = self.send(assoc.foreign_key)
      results = assoc.model_class.where(assoc.primary_key => fk )
      return nil if results.length == 0
      results.first
    end
  end

  def has_many(name, options = {})
    assoc = HasManyOptions.new(name, self.table_name, options)
    define_method(name) do
      pk = self.send(assoc.primary_key)
      results = assoc.model_class.where(assoc.foreign_key => pk )
      results
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
