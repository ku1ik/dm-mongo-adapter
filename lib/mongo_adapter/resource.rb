module DataMapper
  module Mongo
    # Used in preference over DataMapper::Resource to add MongoDB-specific
    # functionality to models.
    module Resource
      def self.included(model)
        model.send(:include, DataMapper::Resource)
        model.send(:include, Modifier)

        # Needs to be after the inclusion of DM::Resource so as to overwrite
        # methods added by DM::Model.
        model.extend(Model)
      end # ResourceMethods

    end # Resource
  end # Mongo
end # DataMapper
