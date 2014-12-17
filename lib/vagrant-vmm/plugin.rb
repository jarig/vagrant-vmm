module VagrantPlugins
  module VMM
    autoload :Action, File.expand_path("../action", __FILE__)
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "VMM provider"
      description <<-DESC
      This plugin installs a provider that allows Vagrant to manage
      machines in Virtual Machine Manager.
      DESC

      provider(:vmm, box_optional: true, priority: 4) do
        require_relative "provider"
        init!
        Provider
      end

      config(:vmm, :provider) do
        require_relative "config"
        init!
        Config
      end

      provider_capability("VMM", "public_address") do
        require_relative "cap/public_address"
        Cap::PublicAddress
      end

      synced_folder(:vmm) do
        require_relative 'synced_folder'
        SyncedFolder
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "locales/en.yml", VMM.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
