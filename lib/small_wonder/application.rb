module SmallWonder
  class Application

    ## In small wonder an application object has the following constituent parts:
    #### node name
    #### application name
    #### version
    #### status
    #### databag-based config data

    attr_accessor :version, :status
    attr_reader :node_name, :application_name, :config_data

    def initialize(node_name, application_name, opts = {})
      @node_name = node_name
      @application_name = application_name

      @config_data = Chef::DataBagItem.load(SmallWonder::Config.databag, application_name).raw_data

      data = Chef::Node.load(node_name)

      unless data[SmallWonder::Config.application_deployment_attribute]
        create_application_deployment_attribute(node_name, application_name)
        data = Chef::Node.load(node_name)
      end

      unless data[SmallWonder::Config.application_deployment_attribute].has_key?(application_name)
        create_application_deployment_attribute_child(node_name, application_name)
        data = Chef::Node.load(node_name)
      end

      unless data[SmallWonder::Config.application_deployment_attribute][application_name]
        update_application_data(node_name, application_name, "version", "0")
        update_application_data(node_name, application_name, "status", "new")
      end

      # set version to application version if we have one
      @version = opts[:version] || nil

      # set status to status before we update for deploy
      @status = opts[:status] || get_status(node_name, application_name)

      # save the data back to the chef node
      update_application_data(node_name, application_name, "status", "initialized")
    end

    def version=(version)
      @version = version
      set_version(@node_name, @application_name, version)
    end

    def status=(status)
      @status = status
      set_status(@node_name, @application_name, status)
    end

    private

    def get_existing_version(node, application)
      version = get_chef_data_value(node, application, "version")

      unless version
        version = "0"
      end

      version
    end

    def set_version(node, application, version)
      update_application_data(node, application, "version", version)
    end

    def get_status(node, application)
      get_chef_data_value(node, application, "status")
    end

    def set_status(node, application, status)
      update_application_data(node, application, "status", status)
    end

    def get_chef_data_value(node, application, key)
      data = Chef::Node.load(node)
      data[SmallWonder::Config.application_deployment_attribute][application][key]
    end

    def create_application_deployment_attribute(node, application)
      data = Chef::Node.load(node)
      data[SmallWonder::Config.application_deployment_attribute] = {}
      data[SmallWonder::Config.application_deployment_attribute][application] = {}
      data.save
    end

    def create_application_deployment_attribute_child(node, application)
      data = Chef::Node.load(node)
      data[SmallWonder::Config.application_deployment_attribute][application] = {}
      data.save
    end

    def update_application_data(node, application, key, value)
      data = Chef::Node.load(node)
      data[SmallWonder::Config.application_deployment_attribute][application][key] = value
      data.save

      #SmallWonder::Log.info("[#{node} // #{application}] #{key} was updated to #{value}")
    end

  end
end

