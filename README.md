## Small Wonder

Small Wonder is a deployment tool.

Specifically it's a lightweight wrapper for Salticid, which is a tool that will run a bunch of commands on a bunch of machines for you. Kinda like capistrano. To a large extent Small Wonder is a means for using Salticid and Chef together to deploy applications. Salticid "roles" and "tasks" are Ruby code and can use the Chef Ruby APIs to search and access anything Chef Client or Knife can (by consuming your knife config). Small Wonder has a notion of an application object as well, this object contains data like the name, version, status and even the databag config data for an application. Name, version and status are saved back to the Chef node so you can use application specific details in your recipes, searches and etc. This application object is available for use in your deployment code as well.

### License

Apache License Version 2.0

### Usage

#### Configure

    $ mkdir ~/.small_wonder
    $ $EDITOR ~/.small_wonder/small_wonder.rb


    chef_repo_path                      "/path/to/chef-repo" # the path to your chef-repo
    ssh_user                            "user" # the ssh user you want Small Wonder and Salticid to use
    application_deployment_attribute    "deployed_applications" # the attribute Small Wonder will save data back to chef using
    config_template_working_directory   "/tmp/small_wonder" # the local directory temporary template work will be done in
    remote_working_dir                  "/tmp/small_wonder_#{Time.now.to_i}" # the remote directory temporary template work will be done in
    application_deployments_dir         "/path/to/chef-repo/application_deployments" # path to your role files
    application_templates_dir           "/path/to/chef-repo/application_templates" # path to your template files
    databag                             "apps" # the databag that contains application configuration data items

In addition to a Small Wonder config, you need a working Knife configuration file.

#### Expectations

Small Wonder expects the names of things to match up. Specifically the application name should be the same as the Salticid role name, databag item and template directory. Note that if an application name has a hyphen in it Small Wonder will convert it to an underscore internally with regards to Salticid roles since they need to be legit Ruby method names.

#### Roles and tasks

Define "roles" using ruby code and splitting deployment operations in to "tasks".

Check out the examples directory for ... well examples.

#### Running small_wonder

A role name should match the name of the application, Chef recipe and databag item your app uses for configuration.

To run the role use:

    $ small_wonder -p example

If you have a specific Chef search query you want to use to as the source of nodes to deploy to:

    $ small_wonder -p example -q "some:attribute"

The default search query is "recipes:example".

You can also specify a version number to pass to the application object:

    $ small_wonder -p example -V 123

#### Chef Data

During the deployment Small Wonder will save data back to the Chef node. Moreover, status is updated to the task currently being run, so you can see live deployment progress in your searches.

If you want to find out details about an app use a knife search like:

    $ knife search node "deployed_applications:example" -a deployed_applications

The output should be something like:

    deployed_applications:
      example:
        status:   final
        version:  851
    id:                              your.server.com

#### Templating

Small wonder supports some basic erb templating just like Chef. All erb files in your 'application_templates_dir' can get populated with data from various Chef objects and attributes. Those files then get scp'd to the server and "overlayed" (read: `cp -R`) on to the installation directory of the application.

Files and directories with 'VERSION' in the name will be convered to have the actual appclication.version variable in place of 'VERSION'.

The examples directory has some examples.