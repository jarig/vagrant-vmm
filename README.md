|Travis CI|Gem|
|----|-----|
| [![Build Status](https://travis-ci.org/jarig/vagrant-vmm.svg?branch=master)](https://travis-ci.org/jarig/vagrant-vmm)|[![Gem Version](https://badge.fury.io/rb/vagrant-vmm.svg)](http://badge.fury.io/rb/vagrant-vmm)|

# Vagrant Virtual Machine Manager (VMM) Plugin

Vagrant is a tool for building and distributing development environments.

This provider will allow you to create VMs in the remote Virtual Machine Manager.

## Installation

Install Vagrant 1.7.1
```
http://www.vagrantup.com/downloads.html
```

Install plugin:
```
vagrant plugin install vagrant-vmm
```

## Prerequisites

1. You should have template in your VMM which has following things setup:
   - WinRM and firewall configured, using:
   ```
   winrm quickconfig
   ```
   - Local user vagrant/vagrant with admin rights.
   Alternatively you can specify other creds using:
   ```
   win64_config.winrm.username = "account_name"
   win64_config.winrm.password = "password"
   ```
   - Once VM created in VMM it should automatically get IP assigned, as well as it should be directly accessible from your machine.
2. Run vagrant under Administrator(in admin shell).



## Usage

Set guest to **:windows**
```
win64_config.vm.guest = :windows
```

Set communicator to **:winrm**
```
win64_config.vm.communicator = "winrm"
```

Set you provider to :vmm and specify at least *vmm_server_address*, *vm_host_group_name* and *vm_template_name* parameters.
```
win64_config.vm.provider :vmm do |conf|
  conf.vm_template_name   = 'vagrant-template-w8.1-64'
  conf.vm_host_group_name = 'Host-Group-Name'
  conf.vmm_server_address = 'my-vmm-server'
  conf.proxy_server_address = '192.126.18.126'  # optional
end
```

## Provider settings

### Template name (required)

VMM template name that will be used for VM creation.

```
conf.vm_template_name = 'vagrant-template-w8.1-64'
```

### VM Host group (required)

VMM host group where VM will be placed.
NOTE: Your template should match it as well.

```
conf.vm_host_group_name = 'Host-Group-Name'
```

### Virtual Machine Manager address (required)

IP/Hostname of the VMM server where VMs are going to be created.
```
conf.vmm_server_address = '192.124.125.10'
```

### Proxy server address (optional)

If your local machine do not have direct access to the machine that hosts VMM, but you have proxy server(jump box) you can specify its IP in *proxy_server_address* property.

```
conf.proxy_server_address = 'my-proxy-to-vmm'
```

### Active Directory settings ( optional )

You can tell the provider to move your VM under some particular OU once it's created.
Here are required options you need to specify for that.

#### ad_server

URL of AD server. Can be derived by running **echo %LOGONSERVER%** command in CMD of the VM environment.
Example:
```
conf.ad_server = 'my-ad-server.some.domain.local'
```

#### ad_source_path

Base DN container where VM appears(and it will be moved from) once it's created.
Example:
```
conf.ad_source_path = 'CN=Computers,DC=some,DC=domain,DC=local'
```

#### ad_target_path

New AD path where VM should be moved to.
Example:
```
conf.ad_target_path = 'OU=Vagrant,OU=Chef-Nodes,DC=some,DC=domain,DC=local'
```

## Troubleshooting

### Hangs on waiting machine to boot

Check that winrm is configured properly in the VM, if default username is used (vagrant/vagrant) then ensure that winrm accepts unencrypted connection and Basic auth.

Enable basic auth and unencrypted connection (in VM).
```
In elevated cmd
winrm set winrm/config/service/auth @{Basic="true"}
winrm set winrm/config/service @{AllowUnencrypted="true"}
```

### Unencrypted traffic is currently disabled in the client configuration

Run following command on your machine as well:
```
In elevated cmd
winrm set winrm/config/service @{AllowUnencrypted="true"}
```

## Contributing

1. Fork it ( https://github.com/jarig/vagrant-vmm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
