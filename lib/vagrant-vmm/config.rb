require "vagrant"

module VagrantPlugins
  module VMM
    class Config < Vagrant.plugin("2", :config)
      # The timeout to wait for an IP address when booting the machine,
      # in seconds.
      #
      # @return [Integer]
      attr_accessor :ip_address_timeout
      # @return [String]
      attr_accessor :proxy_server_address
      # @return [String]
      attr_accessor :vmm_server_address
      # @return [String]
      attr_accessor :vm_template_name
      # @return [String]
      attr_accessor :vm_host_group_name
      # @return [String]
      attr_accessor :vm_address

      def initialize
        @ip_address_timeout = UNSET_VALUE
        @proxy_server_address = UNSET_VALUE
        @vmm_server_address = UNSET_VALUE
        @vm_template_name   = UNSET_VALUE
        @vm_host_group_name = UNSET_VALUE
        @vm_address = UNSET_VALUE
      end

      def finalize!
        if @ip_address_timeout == UNSET_VALUE
          @ip_address_timeout = 60
        end
      end

      def validate(machine)
        errors = _detected_errors

        { "VMM" => errors }
      end
    end
  end
end
