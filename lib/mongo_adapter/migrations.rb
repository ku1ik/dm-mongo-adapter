require 'dm-migrations/auto_migration'

module DataMapper
  module Migrations
    module SingletonMethods
      private
      
      def repository_execute(method, repository_name)
        DataMapper::Model.descendants.each do |model|
          model.send(method, repository_name || model.default_repository_name)
        end
      end
    end
  end

  module Mongo
    module Migrations
      def self.included(base)  
        DataMapper.extend(DataMapper::Migrations::SingletonMethods)
 
        [ :Repository, :Model ].each do |name|
          DataMapper.const_get(name).send(:include, DataMapper::Migrations.const_get(name))
        end
      end

      def storage_exists?(storage_name)
        database.collections.map(&:name).include?(storage_name)
      end

      def create_model_storage(model)
        return false if storage_exists?(model.storage_name)
        database.create_collection(model.storage_name)
      end

      def upgrade_model_storage(model)
        create_model_storage(model)
      end

      def destroy_model_storage(model)
        database.drop_collection(model.storage_name)
      end

     end
  end
end

DataMapper::Mongo.send(:include, DataMapper::Mongo::Migrations)
