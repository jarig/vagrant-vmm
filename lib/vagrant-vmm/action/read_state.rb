
require "log4r"

module VagrantPlugins
  module VMM
    module Action
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::VMM::connection")
        end

        def call(env)
          if env[:machine].id
            vmm_server_address = env[:machine].provider_config.vmm_server_address
            # generate options
            options = {
              vmm_server_address: vmm_server_address,
              proxy_server_address: env[:machine].provider_config.proxy_server_address
            }
            env[:ui].detail("Taking a state of VM #{env[:machine].config.vm.hostname} (id: #{env[:machine].id} )...")
            response = env[:machine].provider.driver.get_current_state(options)
            env[:machine_state_id] = response["state"].downcase.to_sym

            # If the machine isn't created, then our ID is stale, so just
            # mark it as not created.
            if env[:machine_state_id] == :not_created
              env[:machine].id = nil
            end
          else
            env[:machine_state_id] = :not_created
          end
          @app.call(env)
        end
      end
    end
  end
end
