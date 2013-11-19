## stdlib dependencies
require 'yaml'
require 'rexml/document'
require 'net/http'
require 'net/https'
require 'fileutils'

## gem dependencies
require 'chronic'
require 'trollop'
require 'highline/import'

## app dependencies
require 'hcl/utility'
require 'hcl/commands'
require 'hcl/timesheet_resource'
require 'hcl/project'
require 'hcl/task'
require 'hcl/day_entry'

# Workaround for annoying SSL warning:
#  >> warning: peer certificate won't be verified in this SSL session
# http://www.5dollarwhitebox.org/drupal/node/64
class Net::HTTP
  alias_method :old_initialize, :initialize
  def initialize(*args)
    old_initialize(*args)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

module HCl
  VERSION = "0.3.1"

  class App
    include HCl::Utility
    include HCl::Commands

    SETTINGS_FILE = "#{ENV['HOME']}/.hcl/settings.yml"
    CONFIG_FILE = "#{ENV['HOME']}/.hcl/config.yml"
    OLD_SETTINGS_FILE = "#{ENV['HOME']}/.hcl_settings"
    OLD_CONFIG_FILE = "#{ENV['HOME']}/.hcl_config"

    def initialize
      FileUtils.mkdir_p(File.join(ENV['HOME'], ".hcl"))
      read_config
      read_settings
    end

    # Run the given command and arguments.
    def self.command *args
      hcl = new.process_args(*args).run
    end

    # Return true if the string is a known command, false otherwise.
    #
    # @param [#to_s] command name of command
    # @return [true, false]
    def command? command
      Commands.method_defined? command
    end

    # Start the application.
    def run
      begin
        if @command
          if command? @command
            result = send @command, *@args
            if not result.nil?
              if result.respond_to? :join
                puts result.join(', ')
              elsif result.respond_to? :to_s
                puts result
              end
            end
          else
            start @command, *@args
          end
        else
          show
        end
      rescue RuntimeError => e
        STDERR.puts "Error: #{e}"
        exit 1
      rescue SocketError => e
        STDERR.puts "Connection failed. (#{e.message})"
        exit 1
      rescue TimesheetResource::Failure => e
        STDERR.puts "API failure: #{e}"
        exit 1
      end
    end

    def process_args *args
      Trollop::options(args) do
        stop_on Commands.instance_methods
        version "HCl version #{VERSION}"
        banner <<-EOM
HCl is a command-line client for manipulating Harvest time sheets.

Commands:
    # show all available tasks
    hcl tasks

    # set a task alias
    hcl alias <task> <project_id> <task_id>

    # list task aliases
    hcl aliases

    # start a task using an alias
    hcl @<task> [+time] [message]

    # display the daily timesheet
    hcl show [date]

    # stop a running timer
    hcl stop [message]

    # resume the last stopped timer
    hcl resume

    # add a line to your running timer
    hcl note <message>

Examples:
    hcl alias mytask 1234 4567
    hcl @mytask +:15 Doing a thing that I started 15 minutes ago.
    hcl Adding a note to my running task.
    hcl stop That's enough for now.
    hcl resume
    hcl show yesterday
    hcl show last tuesday

Options:
EOM
      end
      @command = args.shift
      @args = args
      self
    end

    protected

    def read_config
      if File.exists? CONFIG_FILE
        config = YAML::load File.read(CONFIG_FILE)
        TimesheetResource.configure config
      elsif File.exists? OLD_CONFIG_FILE
        config = YAML::load File.read(OLD_CONFIG_FILE)
        TimesheetResource.configure config
        write_config config
      else
        config = {}
        puts "Please specify your Harvest credentials.\n"
        config['login'] = ask("Email Address: ").to_s
        config['password'] = ask("Password: ") { |q| q.echo = false }.to_s
        config['subdomain'] = ask("Subdomain: ").to_s
        config['ssl'] = %w(y yes).include?(ask("Use SSL? (y/n): ").downcase)
        TimesheetResource.configure config
        write_config config
      end
    end

    def write_config config
      puts "Writing configuration to #{CONFIG_FILE}."
      File.open(CONFIG_FILE, 'w') do |f|
       f.write config.to_yaml
      end
      FileUtils.chmod 0400, CONFIG_FILE
    end

    def read_settings
      if File.exists? SETTINGS_FILE
        @settings = YAML.load(File.read(SETTINGS_FILE))
      elsif File.exists? OLD_SETTINGS_FILE
        @settings = YAML.load(File.read(OLD_SETTINGS_FILE))
        write_settings
      else
        @settings = {}
      end
    end

    def write_settings
      File.open(SETTINGS_FILE, 'w') do |f|
       f.write @settings.to_yaml
      end
      nil
    end
  end
end

