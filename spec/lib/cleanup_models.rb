module DataMapper::Mongo::Spec
  module CleanupModels

    # Cleans up models after a spec by dropping the Mongo collection,
    # removing the model classes from the descendants list, and then
    # undefining the constants.
    #
    # @todo Only used once; try to remove.
    #
    def cleanup_models(*models)
      unless models.empty?
        model = models.pop
        sym   = model.to_s.to_sym

        if Object.const_defined?(sym)
          if model.respond_to?(:storage_name)
            db = DataMapper::Mongo::Spec.database(model.repository.name)
            db.drop_collection(model.storage_name)
          end

          DataMapper::Model.descendants.delete(model)

          Object.send(:remove_const, sym)
        end

        cleanup_models(*models)
      end
    end

  end # CleanupModels
end # DataMaper::Mongo::Spec
