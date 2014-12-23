require "log4r"

require_relative "driver"
require_relative "plugin"

require "vagrant/util/platform"
require "vagrant/util/powershell"

module VagrantPlugins
  module VMM
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :driver

      def self.usable?(raise_error=false)
        if !Vagrant::Util::Platform.windows?
          raise Errors::WindowsRequired
          return false
        end

        if !Vagrant::Util::Platform.windows_admin?
          raise Errors::AdminRequired
        end

        if !Vagrant::Util::PowerShell.available?
          raise Errors::PowerShellRequired
          return false
        end

        true
      end

      def initialize(machine)
        @machine = machine
        @state_id = nil
        # This method will load in our driver, so we call it now to
        # initialize it.
        machine_id_changed
      end

      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      def machine_id_changed
        @driver = Driver.new(@machine)
      end

      def current_state
        @state_id
      end

      def reset_state
        @state_id = nil
      end

      def state
        @state_id = :not_created if !@machine.id

        if !@state_id || @state_id == :not_created
          env = @machine.action(:read_state)
          @state_id = env[:machine_state_id]
        end

        # Get the short and long description
        short = @state_id.to_s
        long  = ""

        # If we're not created, then specify the special ID flag
        if @state_id == :not_created
          @state_id = Vagrant::MachineState::NOT_CREATED_ID
        end

        # Return the MachineState object
        Vagrant::MachineState.new(@state_id, short, long)
      end

      def to_s
        id = @machine.id.nil? ? "new" : @machine.id
        "VMM (#{id})"
      end

      def ssh_info
        # We can only SSH into a running machine
        return nil if state.id != :running
        address = @machine.provider_config.vm_address || @machine.config.winrm.host
        if !address
          #TODO: call wait_for_ip_address
          return nil
        end

        {
          host: address,
          port: 22,
        }
      end
    end
  end
end
