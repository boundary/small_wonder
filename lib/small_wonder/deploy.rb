module SmallWonder
  class Deploy
    def self.run()
      if SmallWonder::Config.app
        nodes = SmallWonder::Deploy.node_query()

        action = SmallWonder::Config.action.split(",")

        SmallWonder::Deploy.run_action_task(action, SmallWonder::Config.app, nodes)
      else
        SmallWonder::Log.error("No application was specified for your deploy, use the '-p' switch.")
      end
    end

    private

    def self.node_query()
      nodes = []

      if SmallWonder::Config.query
        query = SmallWonder::Config.query
      else
        query = "recipes:#{SmallWonder::Config.app}"
      end

      Chef::Search::Query.new.search(:node, "#{query}") do |n|
        nodes << n[:fqdn]
      end

      nodes
    end

    def self.run_action_task(action, application_name, nodes)
      if nodes.length > 0
        SmallWonder::Log.info("Found the following nodes via your search.")

        nodes.each do |node|
          SmallWonder::Log.info("*  #{node}")
        end

        input = ::HighLine.agree("Are you sure you want to deploy to these nodes [yes|no]?")

        if input
          SmallWonder::Log.info("Commencing deployment.")

          sudo_password = ::HighLine.ask("Your sudo password please:  ") { |q| q.echo = false }

          if SmallWonder::Config.version
            SmallWonder::Log.info("Got version #{SmallWonder::Config.version} from a command line option, using it as the current version for #{SmallWonder::Config.app}.")
          else
            SmallWonder::Log.info("Did not get a app version to deploy on the command line, assuming you will set it during the deploy.")
          end

          metadata = build_metadata(SmallWonder::Config.default_metadata, SmallWonder::Config.dynamic_metadata)

          execute_pre_deploy_hooks(action, application_name, metadata, nodes, SmallWonder::Config.version)

          application_objects = []

          nodes.each do |node|
            if SmallWonder::Config.version
              application = SmallWonder::Application.new(node, application_name, {:version => SmallWonder::Config.version, :metadata => metadata})
            else
              application = SmallWonder::Application.new(node, application_name, {:metadata => metadata})
            end

            deploy_application(action, application, sudo_password)
            application_objects << application
          end

          execute_post_deploy_hooks(action, application_name, metadata, nodes, application_objects, SmallWonder::Config.version)

        end
      else
        SmallWonder::Log.info("No nodes found for your search.")
      end
    end

    def self.deploy_application(action, application, sudo_password)
      run_salticid_task(action, application, sudo_password)

      if SmallWonder::Config.write_node_file
        SmallWonder::Utils.write_node_data_file(application.node_name)
      end
    end

    def self.build_metadata(default = nil, dynamic = nil)
      metadata = Hash.new

      if default
        metadata.store("default", default)
      end

      if dynamic
        metadata.store("dynamic", JSON.parse(dynamic))
      end

      metadata
    end

    def self.build_hook_data(action, application_name, metadata, nodes, application_objects = nil, version = nil)
      if application_objects
        objs = []

        application_objects.each do |obj|
          hash = {}

          obj.instance_variables.each do |var|
            hash.store(var.to_s.delete("@"), obj.instance_variable_get(var))
          end

          objs << hash
        end
      end

      {
        "action" => action,
        "application_name" => application_name,
        "metadata" => metadata,
        "nodes" => nodes,
        "version" => version,
        "application" => objs
      }
    end

    def self.execute_pre_deploy_hooks(action, application_name, metadata, nodes, version)
      data = build_hook_data(action, application_name, metadata, nodes, version)
      execute_hooks(:pre, data)
    end

    def self.execute_post_deploy_hooks(action, application_name, metadata, nodes, application_objects, version)
      data = build_hook_data(action, application_name, metadata, nodes, application_objects, version)
      execute_hooks(:post, data)
    end

    def self.execute_hooks(type, data)
      data_json = data.to_json

      case type
      when :pre
        hooks = SmallWonder::Config.pre_deploy_hooks
      when :post
        hooks = SmallWonder::Config.post_deploy_hooks
      end

      if hooks
        hooks.each do |cmd|
          begin
            SmallWonder::Log.info("Running #{type} deploy hook, command: #{cmd}")
            output = `#{cmd} \'#{data_json}\'`
            SmallWonder::Log.debug("#{type} deploy hook output:")
            SmallWonder::Log.debug(output)
          rescue Exception => e
            SmallWonder::Log.fatal("#{type} deploy hook failed, command: #{cmd}, data: #{data_json}")
          end
        end
      end

    end

    ## deploy step
    # Creates a new salticid host for node, and calls <app>.deploy on it.
    def self.run_salticid_task(action, application, sudo_password)
      SmallWonder::Log.info("Running #{application.application_name} deployment for #{application.node_name} ...")

      host = SmallWonder.salticid.host application.node_name
      host.on_log do |message|
        begin
          level = {'stderr' => 'fatal', nil => 'info'}
          level.default = 'info'
          severity = message.severity || 'info'
          SmallWonder::Log.send(level[message.severity], message.text)
        rescue => e
          p e
        end
      end

      host.application = application
      host.user SmallWonder::Config.ssh_user
      host.password = sudo_password

      # sub hyphens for underscores to work around having hyphens in method names
      host.role application.application_name.gsub("-", "_")

      action.each do |x|
        host.send(application.application_name.gsub("-", "_")).__send__(x)
      end

      # set the application status to final since the deploy is done
      application.status = "final"
    end

  end
end
