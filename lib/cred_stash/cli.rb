require 'thor'

module CredStash
  class CLI < Thor
    desc "get [key name]", "Show a value for key name"
    method_option :version, type: :string, aliases: '-v', desc: 'Specify version'
    def get(name)
      if options[:version]
        puts CredStash.get(name, version: options[:version])
      else
        puts CredStash.get(name)
      end
    end

    desc "put [key name]", "Put a value for key name"
    option :kms_key_id , :desc => "the KMS key-id of the master key to use. Defaults to alias/credstash"
    def put(name)
      value = Readline.readline("secret value> ")
      kms_key_id = options[:kms_key_id] if options[:kms_key_id]
      CredStash.put(name, value, kms_key_id: kms_key_id)
      puts "#{name} has stored."
    end

    desc "list", "Show all stored keys"
    method_option :version, type: :boolean, aliases: '-v', desc: 'Show version.'
    def list()
      if options[:version]
        puts CredStash.list_with_version
      else
        puts CredStash.list.keys
      end
    end

    desc "delete [key name]", "Delete a key"
    def delete(name)
      CredStash.delete(name)
      puts "#{name} has deleted."
    end

    desc "setup", "Setup credstash repository on DynamoDB"
    def setup
      CredStash.setup
      puts "Set up successfully"
    end
  end
end
