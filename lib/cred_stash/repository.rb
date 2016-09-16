require 'cred_stash/repository/item'
require 'cred_stash/repository/dynamo_db'

module CredStash::Repository
  def self.instance
    case CredStash.config.storage
    when :dynamodb
      DynamoDB.new
    else
      raise ArgumentError, "Unknown storage #{CredStash.config.storage}"
    end
  end
end
