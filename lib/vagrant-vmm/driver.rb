require "json"

require "vagrant/util/powershell"

require_relative "plugin"

module VagrantPlugins
  module VMM
    class Driver
      ERROR_REGEXP  = /===Begin-Error===(.+?)===End-Error===/m
      OUTPUT_REGEXP = /===Begin-Output===(.+?)===End-Output===/m

      attr_reader :vm_id
      attr_reader :machine

      def initialize(machine)
        @machine = machine
        @vm_id = machine.id
        @logger = Log4r::Logger.new("vagrant::provider::vmm")
      end

      def execute(path, options, print_output = false)
        r = execute_powershell(path, options) { |io_name, data|
          if print_output && ( io_name == :stderr || io_name == :stdout )
            if !OUTPUT_REGEXP.match(data) && !ERROR_REGEXP.match(data)
              if io_name == :stdout
                machine.ui.output(data)
              end
              if io_name == :stderr
                machine.ui.error(data)
              end
            end
          end
        }
        if r.exit_code != 0
          raise Errors::PowerShellError,
            script: path,
            stderr: r.stderr
        end

        # We only want unix-style line endings within Vagrant
        r.stdout.gsub!("\r\n", "\n")
        r.stderr.gsub!("\r\n", "\n")

        error_match  = ERROR_REGEXP.match(r.stdout)
        output_match = OUTPUT_REGEXP.match(r.stdout)

        if error_match
          data = JSON.parse(error_match[1])

          # We have some error data.
          raise Errors::PowerShellError,
            script: path,
            stderr: data["error"]
        end

        # Nothing
        return nil if !output_match
        return JSON.parse(output_match[1])
      end

      def get_current_state(options)
        options['vm_id'] = vm_id
        execute('get_vm_status.ps1', options)
      end

       def delete_vm
         options['vm_id'] = vm_id
         execute('delete_vm.ps1', options)
       end

       def read_guest_ip(options)
         options['vm_id'] = vm_id
         execute('get_network_config.ps1', options, true)
       end

       def resume(options)
         options['vm_id'] = vm_id
         execute('resume_vm.ps1', options)
       end

       def start(options)
         options['vm_id'] = vm_id
         execute('start_vm.ps1', options)
       end

       def stop(options)
         options['vm_id'] = vm_id
         execute('stop_vm.ps1', options)
       end

       def suspend(options)
         options['vm_id'] = vm_id
         execute("suspend_vm.ps1", options)
       end

       def import(options)
         execute('import_vm.ps1', options)
       end

       def sync_folders(options)
         execute('sync_folders.ps1', options)
       end

      protected

      def execute_powershell(path, options, &block)
        lib_path = Pathname.new(File.expand_path("../scripts", __FILE__))
        path = lib_path.join(path).to_s.gsub("/", "\\")
        options = options || {}
        ps_options = []
        options.each do |key, value|
          ps_options << "-#{key}"
          ps_options << "'#{value}'"
        end

        # Always have a stop error action for failures
        ps_options << "-ErrorAction" << "Stop"

        opts = { notify: [:stdout, :stderr, :stdin] }
        Vagrant::Util::PowerShell.execute(path, *ps_options, **opts, &block)
      end
    end
  end
end
