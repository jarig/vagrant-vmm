module VagrantPlugins
  module VMM
    module Action
      class ResumeVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          vmm_server_address = env[:machine].provider_config.vmm_server_address
          # generate options
          options = {
            vmm_server_address: vmm_server_address,
            proxy_server_address: env[:machine].provider_config.proxy_server_address
          }
          env[:ui].info("Resuming the machine...")
          env[:machine].provider.driver.resume(options)
          env[:machine].provider.reset_state

          @app.call(env)
        end
      end
    end
  end
end
