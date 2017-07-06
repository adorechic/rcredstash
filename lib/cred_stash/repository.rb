require 'cred_stash/repository/item'
require 'cred_stash/repository/dynamo_db'

module CredStash::Repository
  def self.instance
    case CredStash.config.storage
    when :dynamodb
      DynamoDB.new
    when :dynamodb_local
      endpoint = ENV['DYNAMODB_URL'] || 'http://localhost:8000'
      DynamoDB.new(
        client: Aws::DynamoDB::Client.new(
          endpoint: endpoint,
        )
      )
    else
      raise ArgumentError, "Unknown storage #{CredStash.config.storage}"
    end
  end
end
