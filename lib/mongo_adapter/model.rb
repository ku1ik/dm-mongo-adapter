module DataMapper
  module Mongo
    module Model
      # Defines a Property on the Resource
      #
      # Overrides the property method in dm-core so as to automatically map
      # Array and Hash types to EmbeddedArray and EmbeddedHash respectively.
      #
      # @param [Symbol] name
      #   the name for which to call this property
      # @param [Type] type
      #   the type to define this property ass
      # @param [Hash(Symbol => String)] options
      #   a hash of available options
      #
      # @return [Property]
      #   the created Property
      #
      # @api public
      def property(name, type, options = {})
        if Array == type
          type = DataMapper::Mongo::Property::Array
        elsif Hash == type
          type = DataMapper::Mongo::Property::Hash
        elsif DateTime == type
          type = DataMapper::Mongo::Types::DateTime
        elsif Date == type
          type = DataMapper::Mongo::Types::Date
        end

        super(name, type, options)
      end

      private

      # @api private
      def const_missing(name)
        if DataMapper::Mongo::Property.const_defined?(name)
          DataMapper::Mongo::Property.const_get(name)
        else
          super
        end
      end
    end # Model
  end # Mongo
end # DataMapper
