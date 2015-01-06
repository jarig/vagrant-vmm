require "fileutils"

require "log4r"

module VagrantPlugins
  module VMM
    module Action
      class Import
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::VMM::import")
        end

        def call(env)
          vmm_server_address = env[:machine].provider_config.vmm_server_address
          # generate options
          options = {
            vmm_server_address: vmm_server_address,
            proxy_server_address: env[:machine].provider_config.proxy_server_address,
            vm_name: env[:machine].config.vm.hostname,
            vm_template_name: env[:machine].provider_config.vm_template_name,
            vm_host_group_name: env[:machine].provider_config.vm_host_group_name,
            ad_server: env[:machine].provider_config.ad_server,
            ad_source_path: env[:machine].provider_config.ad_source_path,
            ad_target_path: env[:machine].provider_config.ad_target_path
          }

          #
          env[:ui].detail("Creating and registering VM in the VMM (#{vmm_server_address})...")
          if options[:ad_server] && options[:ad_source_path] && options[:ad_target_path]
            env[:ui].detail("  ..and moving it under #{options[:ad_target_path]} after it's created.")
          end
          server = env[:machine].provider.driver.import(options)
          env[:ui].detail("Successfully created the VM with name: #{server['name']}")
          env[:machine].id = server["id"]
          @app.call(env)
        end
      end
    end
  end
end
