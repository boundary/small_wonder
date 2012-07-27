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

    def main()

      cli = SmallWonder::CLI.new
      cli.parse_options

      # consume small wonder config
      SmallWonder::Utils.consume_config_file(cli, cli.config[:config_file])

      unless SmallWonder::Utils.sane_working_dir?(SmallWonder::Config.remote_working_dir)
        SmallWonder::Log.error("Your remote working dir looks strange (#{SmallWonder::Config.remote_working_dir})")
        exit(1)
      end

      unless SmallWonder::Utils.sane_working_dir?(SmallWonder::Config.config_template_working_directory)
        SmallWonder::Log.error("Your local working dir looks strange (#{SmallWonder::Config.config_template_working_directory})")
        exit(1)
      end

      SmallWonder::Utils.consume_config_file(cli, cli.config[:knife_config_file])

      # inintialize chef/knife config
      Chef::Config[:node_name] = SmallWonder::Config.node_name
      Chef::Config[:client_key] = SmallWonder::Config.client_key
      Chef::Config[:chef_server_url] = SmallWonder::Config.chef_server_url

      # Set up salticid
      self.salticid = Salticid.new
      self.salticid.load(File.expand_path(File.join(
        SmallWonder::Config.application_deployments_dir, '**', '*.rb')))

      case SmallWonder::Config.action
      when "none"
        SmallWonder::Log.info("No action specified, assuming deploy ...")
        SmallWonder::Deploy.run
      when "deploy"
        SmallWonder::Deploy.run
      when "vicki"
        system("open http://www.youtube.com/watch?v=ukSvjqwJixw")
      else
        SmallWonder::Log.error("Supported action \"#{SmallWonder::Config.action}\"!")
      end

    end

  end
end
