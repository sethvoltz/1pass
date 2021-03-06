require 'io/console'
require 'thor'

require 'OnePass/application'
require 'OnePass/password'

module OnePass
  # OnePass CLI
  class CLI < Thor
    SHOW_OPTIONS = %w( all username password url uuid title ).freeze

    map %w(--version -v) => :__version
    desc '--version, -v', 'Print the current version'
    def __version
      puts "#{File.basename $PROGRAM_NAME} version #{OnePass::VERSION}"
    end

    desc 'login', 'Save a 1Password vault and verify password'
    option :vault, aliases: '-v', type: :string, banner: 'Specify a vault path', required: true
    def login
      OnePass::Application.save options.vault
    end

    desc 'logout', 'Forget any saved 1Password vault'
    def logout
      OnePass::Application.forget
    end

    desc 'show [type] {NAME|UUID}', 'Get a single item from your vault, use only one type'
    option :clip, aliases: '-c', type: :boolean, banner: 'Copy value to clipboard instead of stdout'
    SHOW_OPTIONS.each do |switch|
      option switch.to_sym, type: :boolean
    end

    def show(name)
      # Check for multiple mutex args
      type = SHOW_OPTIONS.each_with_object(Hash.new) do |k, hash|
        hash[k] = options[k] if options.has_key?(k)
      end
      if type.length > 1
        puts "Use only one of #{SHOW_OPTIONS.collect { |switch| '--' + switch }.join ', '}"
        exit 1
      end

      # TODO: Check if name looks like a UUID
      # otherwise, search for title by substring, return first
      app = OnePass::Application.new
      reply_type = type.keys.first.to_sym
      reply = app.show name, reply_type
      if options.clip
        IO.popen('pbcopy', 'w') { |f| f << (reply_type == :all ? JSON.generate(reply) : reply) }
      else
        print reply_type == :all ? JSON.pretty_generate(reply) : reply
        puts if $stdout.isatty
      end
    end

    desc 'search QUERY', 'Perform fuzzy search for items in your vault, shows uuid, title and username'
    def search(query)
      app = OnePass::Application.new
      puts JSON.pretty_generate(app.search(query))
    end

    map ls: :list
    desc 'list FOLDER', 'List the contents of a folder, shows title and username'
    def list(folder)
    end
  end
end
