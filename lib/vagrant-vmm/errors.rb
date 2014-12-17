module VagrantPlugins
  module VMM
    module Errors
      # A convenient superclass for all our errors.
      class VMMError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_VMM.errors")
      end

      class AdminRequired < VMMError
        error_key(:admin_required)
      end

      class BoxInvalid < VMMError
        error_key(:box_invalid)
      end

      class IPAddrTimeout < VMMError
        error_key(:ip_addr_timeout)
      end

      class NoSwitches < VMMError
        error_key(:no_switches)
      end

      class PowerShellFeaturesDisabled < VMMError
        error_key(:powershell_features_disabled)
      end

      class PowerShellError < VMMError
        error_key(:powershell_error)
      end

      class PowerShellRequired < VMMError
        error_key(:powershell_required)
      end

      class WindowsRequired < VMMError
        error_key(:windows_required)
      end
    end
  end
end
