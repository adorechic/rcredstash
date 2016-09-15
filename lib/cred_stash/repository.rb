require 'cred_stash/repository/item'
require 'cred_stash/repository/dynamo_db'

module CredStash::Repository
  def self.instance
    DynamoDB.new
  end
end
