require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do

      through_options = self.class.assoc_options[through_name]
      through_class = through_options.model_class
      through_table = through_class.table_name
      through_pk = through_options.primary_key
      through_fk = through_options.foreign_key


      source_options = through_class.assoc_options[source_name]

      source_class = source_options.model_class
      source_table = source_class.table_name
      source_pk = source_options.primary_key
      source_fk = source_options.foreign_key

      id = self.send(through_options.foreign_key)
      # self.send(through_name).send(source_name)
      results = DBConnection.execute(<<-SQL, id)
        SELECT #{source_table}.*
        FROM
          #{through_table}
        INNER JOIN
          #{source_table}
        ON
          #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
        WHERE
          #{through_table}.#{through_pk} = ?
      SQL

      source_class.prase_all(results).first
    end
  end
end
