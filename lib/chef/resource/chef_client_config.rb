#
# Copyright:: Copyright (c) Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../resource"
require_relative "../dist"

class Chef
  class Resource
    class ChefClientConfig < Chef::Resource
      unified_mode true

      provides :chef_client_config

      description "Use the **chef_client_config** resource to create a client.rb file in the #{Chef::Dist::PRODUCT} configuration directory. See the [client.rb docs](https://docs.chef.io/config_rb_client/) for more details on options available in the client.rb configuration file."
      introduced "16.5"
      examples <<~DOC
      DOC

      # @todo policy_file or policy_group being set requires the other to be set so enforce that.

      property :config_directory, String,
        description: "The directory to store the client.rb in.",
        default: Chef::Dist::CONF_DIR

      property :user, String,
        description: "The user that should own the client.rb file and the configuration directory if it needs to be created."

      property :node_name, String,
        description: "The name of the node. This determines which configuration should be applied and sets the `client_name`, which is the name used when authenticating to a #{Chef::Dist::SERVER_PRODUCT}. If this value is not provided Chef Infra Client will use the node's FQDN as the node name. In general, Chef recommends that you leave this setting blank and let the client assign the FQDN of the node as the node_name during each Chef Infra Client run."

      property :chef_server_url, String,
        description: "The URL for the #{Chef::Dist::SERVER_PRODUCT}.",
        required: true

      # @todo Allow passing this as a string and convert it to the symbol
      property :ssl_verify_mode, Symbol,
        equal_to: %i{verify_none verify_peer},
        description: <<~DESC
        Set the verify mode for HTTPS requests.

        * Use :verify_none for no validation of SSL certificates.
        * Use :verify_peer for validation of all SSL certificates, including the #{Chef::Dist::SERVER_PRODUCT} connections, S3 connections, and any HTTPS remote_file resource URLs used in #{Chef::Dist::PRODUCT} runs. This is the recommended setting.
        DESC

      property :formatters, Array,
        description: ""

      property :event_loggers, Array,
        description: ""

      property :log_level, Symbol,
        description: "",
        equal_to: %i{auto trace debug info warn fatal}

      property :log_location, String,
        description: ""

      property :http_proxy, String,
        description: "The proxy server to use for HTTP connections."

      property :https_proxy, String,
        description: "The proxy server to use for HTTPS connections."

      property :ftp_proxy, String,
      description: "The proxy server to use for FTP connections."

      property :no_proxy, [String, Array],
        description: "A comma-separated list or an array of URLs that do not need a proxy.",
        coerce: proc { |x| x.is_a?(Array) ? x.join(",") : x }

      # @todo we need to fixup bad plugin naming inputs here
      property :ohai_disabled_plugins, Array
        description: ""

      # @todo we need to fixup bad plugin naming inputs here
      property :ohai_optional_plugins, Array,
        description: ""

      property :minimal_ohai, [true, false],
        description: "Run a minimal set of Ohai plugins providing data necessary for the execution of #{Chef::Dist::PRODUCT}'s built-in resources. Setting this to true will skip many large and time consuming data sets such as `cloud` or `packages`. Setting this this to true may break cookbooks that assume all Ohai data will be present."

      property :start_handlers, Array,
        description: ""

      property :report_handlers, Array,
        description: ""

      property :exception_handlers, Array,
        description: ""

      property :chef_license, String,
        description: "",
        equal_to: %w{accept accept-no-persist accept-silent}

      property :policy_name, String,
        description: "The name of a policy, as identified by the `name` setting in a Policyfile.rb file. `policy_group`  when setting this property."

      property :policy_group, String,
        description: "The name of a `policy group` that exists on the #{Chef::Dist::SERVER_PRODUCT}. `policy_name` must also be specified when setting this property."

      property :named_run_list, String,
        description: "A specific named runlist defined in the node's applied Policyfile, which the should be used when running #{Chef::Dist::PRODUCT}."

      property :pid_file, String,
        description: "The location in which a process identification number (pid) is saved. An executable, when started as a daemon, writes the pid to the specified file. "

      property :file_cache_path, String,
        description: "The location in which cookbooks (and other transient data) files are stored when they are synchronized. This value can also be used in recipes to download files with the `remote_file` resource."

      property :file_backup_path, String,
        description: "The location in which backup files are stored. If this value is empty, backup files are stored in the directory of the target file"

      property :run_path, String,
        description: ""

      property :file_staging_uses_destdir, String,
        description: "How file staging (via temporary files) is done. When `true`, temporary files are created in the directory in which files will reside. When `false`, temporary files are created under `ENV['TMP']`"

      action :create do
        unless ::Dir.exist?(new_resource.config_directory)
          directory new_resource.config_directory do
            user new_resource.user unless new_resource.user.nil?
            mode "0750"
            recursive true
          end
        end

        unless ::Dir.exist?(::File.join(new_resource.config_directory, "client.d"))
          directory ::File.join(new_resource.config_directory, "client.d") do
            user new_resource.user unless new_resource.user.nil?
            mode "0750"
            recursive true
          end
        end

        template ::File.join(new_resource.config_directory, "client.rb") do
          source ::File.expand_path("support/client.erb", __dir__)
          local true
          variables(
            chef_license: new_resource.chef_license,
            chef_server_url: new_resource.chef_server_url,
            event_loggers: new_resource.event_loggers,
            exception_handlers: new_resource.exception_handlers,
            file_backup_path: new_resource.file_backup_path,
            file_cache_path: new_resource.file_cache_path,
            file_staging_uses_destdir: new_resource.file_staging_uses_destdir,
            formatters: new_resource.formatters,
            http_proxy: new_resource.http_proxy,
            https_proxy: new_resource.https_proxy,
            ftp_proxy: new_resource.ftp_proxy,
            log_level: new_resource.log_level,
            log_location: new_resource.log_location,
            minimal_ohai: new_resource.minimal_ohai,
            named_run_list: new_resource.named_run_list,
            no_proxy: new_resource.no_proxy,
            node_name: new_resource.node_name,
            ohai_disabled_plugins: new_resource.ohai_disabled_plugins,
            ohai_optional_plugins: new_resource.ohai_optional_plugins,
            pid_file: new_resource.pid_file,
            policy_group: new_resource.policy_group,
            policy_name: new_resource.policy_name,
            report_handlers: new_resource.report_handlers,
            run_path: new_resource.run_path,
            ssl_verify_mode: new_resource.ssl_verify_mode,
            start_handlers: new_resource.start_handlers
          )
          mode "0640"
          action :create
        end
      end

      action :remove do
        file ::File.join(new_resource.config_directory, "client.rb") do
          action :delete
        end
      end
    end
  end
end
