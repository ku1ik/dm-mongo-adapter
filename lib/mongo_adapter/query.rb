module DataMapper
  module Mongo
    # This class is responsible for taking Query instances from DataMapper and
    # formatting the query such that it can be performed by the Mongo library.
    class Query
      include DataMapper::Assertions
      include DataMapper::Query::Conditions

      # Creates a new Query instance
      #
      # @param [Mongo::Collection] collection
      # @param [DataMapper::Query] query
      #
      # @api semipublic
      def initialize(collection, query)
        assert_kind_of 'collection', collection, ::Mongo::Collection
        assert_kind_of 'query', query, DataMapper::Query

        @collection = collection
        @query      = query
        @statements = {}
        @conditions = Conditions.new(query.conditions)
      end

      # Applies the query to the collection
      #
      # Reads the query options, fetches the resources matching the query
      # statements and filters according to the conditions.
      #
      # @return [Mongo::Collection]
      #
      # @api semipublic
      def read
        setup_conditions_and_options
        find
      end

      # TODO: document
      # @api semipublic
      def count
        setup_conditions_and_options

        # TODO: atm ruby driver doesn't support count with statements,
        #        that's why we use find and size here as a tmp workaround
        if @statements.blank?
          [@collection.count]
        else
          [find.size]
        end
      end

      # TODO: document
      # @api semipublic
      def group
        setup_conditions_and_options

        property_names = []
        operators = []
        keys = []

        @query.fields.each do |field|
          if field.kind_of?(DataMapper::Query::Operator)
            operators << field
            property_names << field.target.name
          else
            keys << field.name
            property_names << field.name
          end
        end

        if operators.blank?
          initial  = {}
          reduce   = JavaScript::Reduce.new.to_s
          finalize = nil
        else
          js_operation = JavaScript::Operation.new(operators)

          initial  = js_operation.initial
          reduce   = js_operation.reduce
          finalize = js_operation.finalize

          keys = keys - initial.keys
        end
        
        @collection.group(keys, @statements, initial, reduce, finalize).map do |records|
          records.to_mash.symbolize_keys.only(*property_names)
        end
      end

      private

      # TODO: document
      # @api private
      def setup_conditions_and_options
        @options = {}
        
        @options[:limit] = @query.limit  if @query.limit
        @options[:skip]  = @query.offset if @query.offset
        @options[:sort]  = sort_statement(@query.order) unless @query.order.empty?

        conditions_statement(@query.conditions)
      end

      # TODO: document
      # @api private
      def find
        @conditions.filter_collection!(@collection.find(@statements, @options).to_a)
      end

      # Takes a condition and returns a Mongo-compatible hash
      #
      # @param [DataMapper::Query::Conditions::AbstractOperation, DataMapper::Query::Conditions::AbstractComparison] operation
      #   An operation to be made suitable for use with Mongo
      # @param [Boolean] affirmative
      #   Are we looking for resources which match the condition (true), or
      #   those which do not match (false)
      #
      # @return [Hash]
      #
      # @api private
      def conditions_statement(conditions, affirmative = true)
        case conditions
        when AbstractOperation  then operation_statement(conditions, affirmative)
        when AbstractComparison then comparison_statement(conditions, affirmative)
        end
      end

      # Takes a Operation condition and returns a Mongo-compatible hash
      #
      # @param [DataMapper::Query::Conditions::Operation] operation
      #   An operation to be made suitable for use with Mongo
      # @param [Boolean] affirmative
      #   Are we looking for resources which match the condition (true), or
      #   those which do not match (false)
      #
      # @return [Hash]
      #
      # @api private
      def operation_statement(operation, affirmative = true)
        case operation
        when NotOperation then conditions_statement(operation.first, !affirmative)
        when AndOperation then operation.each{|op| conditions_statement(op, affirmative)}
        when OrOperation  then operation.each{|op| conditions_statement(op, affirmative)}
        end
      end

      # Takes a Comparison condition and returns a Mongo-compatible hash
      #
      # @param [DataMapper::Query::Conditions::Comparison] comparison
      #   An comparison to be made suitable for use with Mongo
      # @param [Boolean] affirmative
      #   Are we looking for resources which match the condition (true), or
      #   those which do not match (false)
      #
      # @return [Hash]
      #
      # @api private
      def comparison_statement(comparison, affirmative = true)
        if comparison.relationship?
          return conditions_statement(comparison.foreign_key_mapping, affirmative)
        end

        update_statements(comparison, comparison.subject.field, affirmative)
      end

      # TODO: document
      # @api private
      def
        update_statements(comparison, field, affirmative = true)
        value = if comparison.value.kind_of?(Array)
          comparison.value.map { |value| value.class.to_mongo(value) }
        else
          comparison.value.class.to_mongo(comparison.value)
        end

        operator = if affirmative
          case comparison
            when EqualToComparison              then value
            when GreaterThanComparison          then {'$gt'  => value}
            when LessThanComparison             then {'$lt'  => value}
            when GreaterThanOrEqualToComparison then {'$gte' => value}
            when LessThanOrEqualToComparison    then {'$lte' => value}
            when InclusionComparison            then inclusion_comparison_operator(comparison, value)
            when RegexpComparison               then value
            when LikeComparison                 then comparison.send(:expected)
          else
            raise NotImplementedError
          end
        else
          case comparison
            when EqualToComparison              then {'$ne'  => value}
            when InclusionComparison            then {'$nin' => value}
            when RegexpComparison               then {'$not' => value}
          else
            raise NotImplementedError
          end
        end

        operator.is_a?(Hash) ?
          (@statements[field.to_sym] ||= {}).merge!(operator) : @statements[field.to_sym] = operator
      end

      # Creates Mongo's equivalent of an IN() condition
      #
      # @param [DataMapper::Query::Conditions::Comparison] comparison
      #   An comparison to be made suitable for use with Mongo
      # @param [Object] value
      #   The value to match against.
      #
      # @return [Hash]
      #
      # @api private
      def inclusion_comparison_operator(comparison, value)
        if value.kind_of?(Range)
          {'$gte' => value.first, value.exclude_end? ? '$lt' : '$lte' => value.last}
        elsif comparison.kind_of?(InclusionComparison) && value.size == 1
          value.first
        elsif comparison.subject.type == DataMapper::Mongo::Property::Array
          value
        else
          {'$in'  => value}
        end
      end

      # Constructs a sort statement which can be used by the Mongo library
      #
      # Mongo::Collection#find requires that sort statements consist of an
      # array where each element is another array containing the field name
      # and the sort order.
      #
      # @param [Enumerable<DataMapper::Query::Direction>]
      #
      # @return [Array<Array>]
      #
      # @api private
      def sort_statement(conditions)
        conditions.inject([]) do |sort_arr, condition|
          sort_arr << [condition.target.field, condition.operator == :asc ? 'ascending' : 'descending']
        end
      end

    end # Query
  end # Mongo
end # DataMapper
