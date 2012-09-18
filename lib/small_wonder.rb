require 'rubygems'

require 'socket'
require 'excon'
require 'mixlib/config'
require 'mixlib/cli'
require 'mixlib/log'
require 'yajl/json_gem'
require 'salticid'
require 'chef'
require 'highline/import'
require 'erb'
require 'net/scp'
require 'tmpdir'

__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require 'small_wonder/log'
require 'small_wonder/cli'
require 'small_wonder/config'
require 'small_wonder/utils'
require 'small_wonder/deploy'
require 'small_wonder/application'
require 'small_wonder/configuratorator'

require 'small_wonder/salticid_monkeypatch'

module SmallWonder
  class << self

    def salticid=(h)
      @salticid = h
    end

    def salticid
      @salticid
    end

    def long_main()

      cli = SmallWonder::CLI.new
      cli.parse_options

      # consume small wonder config
      SmallWonder::Utils.consume_config_file(cli, cli.config[:config_file])

      # consume knife config
      SmallWonder::Utils.consume_config_file(cli, cli.config[:knife_config_file])

      main()
    end

    def short_main()

      cli = SmallWonder::CLI.new
      cli.parse_options

      # consume small wonder config
      SmallWonder::Utils.consume_config_file(cli, cli.config[:config_file])

      # consume knife config
      SmallWonder::Utils.consume_config_file(cli, cli.config[:knife_config_file])

      # sw facade deploy [fqdn]
      SmallWonder::Config.app = ARGV[0]
      SmallWonder::Config.action = ARGV[1]

      if ARGV[2]
        SmallWonder::Config.query = "fqdn:#{ARGV[2]}"
      end

      main()
    end

    def main()

      #unless SmallWonder::Utils.sane_working_dir?(SmallWonder::Config.remote_working_dir)
      #  SmallWonder::Log.error("Your remote working dir looks strange (#{SmallWonder::Config.remote_working_dir})")
      #  exit(1)
      #end

      #unless SmallWonder::Utils.sane_working_dir?(SmallWonder::Config.config_template_working_directory)
      #  SmallWonder::Log.error("Your local working dir looks strange (#{SmallWonder::Config.config_template_working_directory})")
      #  exit(1)
      #end

      # inintialize chef/knife config
      Chef::Config[:node_name] = SmallWonder::Config.node_name
      Chef::Config[:client_key] = SmallWonder::Config.client_key
      Chef::Config[:chef_server_url] = SmallWonder::Config.chef_server_url

      # Set up salticid
      self.salticid = Salticid.new
      self.salticid.load(File.expand_path(File.join(
        SmallWonder::Config.application_deployments_dir, '**', '*.rb')))

      case SmallWonder::Config.action
      when "vicki"
        system("open http://www.youtube.com/watch?v=ukSvjqwJixw")
      else
        SmallWonder::Log.info("Using specified action: #{SmallWonder::Config.action}")
        SmallWonder::Deploy.run
      end

    end

  end
end
