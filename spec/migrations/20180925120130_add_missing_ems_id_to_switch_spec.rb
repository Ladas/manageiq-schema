require_migration

describe AddMissingEmsIdToSwitch do
  let(:switch_stub) { migration_stub(:Switch) }
  let(:host_stub) { migration_stub(:Host) }
  let(:ems_stub) { migration_stub(:ExtManagementSystem) }

  migration_context :up do
    it "migrates a series of representative rows" do
      # Emses
      vmware_ems = ems_stub.create!(:type => "ManageIQ::Providers::Vmware::InfraManager")
      redhat_ems = ems_stub.create!(:type => "ManageIQ::Providers::Redhat::InfraManager")
      lenovo_ems = ems_stub.create!(:type => "ManageIQ::Providers::Lenovo::PhysicalInfraManager")

      # Hosts
      host_esx          = host_stub.create!(:type                  => "ManageIQ::Providers::Vmware::InfraManager::HostEsx",
                                            :ext_management_system => vmware_ems)
      host_esx_archived = host_stub.create!(:type                  => "ManageIQ::Providers::Vmware::InfraManager::HostEsx",
                                            :ext_management_system => nil)

      host_redhat = host_stub.create!(:type                  => "ManageIQ::Providers::Redhat::InfraManager::Host",
                                      :ext_management_system => redhat_ems)

      # Switches
      dvswitch               = switch_stub.create!(:name => "DVS", :uid_ems => "dvswitch-1", :shared => true,
                                                   :type => "ManageIQ::Providers::Vmware::InfraManager::DistributedVirtualSwitch")
      dvswitch_without_assoc = switch_stub.create!(:name                  => "DVS", :uid_ems => "dvswitch-3", :shared => true,
                                                   :host                  => host_esx,
                                                   :ext_management_system => vmware_ems,
                                                   :type                  => "ManageIQ::Providers::Vmware::InfraManager::DistributedVirtualSwitch")
      dvswitch_archived    = switch_stub.create!(:name                  => "DVS", :uid_ems => "dvswitch-1", :shared => true,
                                                 :ext_management_system => vmware_ems,
                                                 :type                  => "ManageIQ::Providers::Vmware::InfraManager::DistributedVirtualSwitch")
      host_switch          = switch_stub.create!(:name => "vSwitch0", :uid_ems => "vSwitch0",
                                                 :type => "ManageIQ::Providers::Vmware::InfraManager::HostVirtualSwitch")
      host_switch_archived = switch_stub.create!(:name                  => "vSwitch0", :uid_ems => "vSwitch0",
                                                 :ext_management_system => vmware_ems,
                                                 :type                  => "ManageIQ::Providers::Vmware::InfraManager::HostVirtualSwitch")
      redhat_switch        = switch_stub.create!(:name => "vSwitch0", :uid_ems => "vSwitch0")
      physical_switch      = switch_stub.create!(:name                  => "Physical Switch", :uid_ems => "switch-1",
                                                 :type                  => "ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch",
                                                 :ext_management_system => lenovo_ems)
      physical_switch1     = switch_stub.create!(:name                  => "Physical Switch", :uid_ems => "switch-1",
                                                 :type                  => "ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalSwitch",
                                                 :ext_management_system => nil)

      # Host -> switches mapping
      host_esx.host_switches.create!(:host => host_esx, :switch => dvswitch)
      host_esx.host_switches.create!(:host => host_esx, :switch => host_switch)
      host_esx_archived.host_switches.create!(:host => host_esx_archived, :switch => host_switch_archived)
      host_esx_archived.host_switches.create!(:host => host_esx_archived, :switch => dvswitch_archived)
      host_redhat.host_switches.create!(:host => host_redhat, :switch => redhat_switch)

      migrate

      expect(dvswitch.reload.ems_id).to eq(vmware_ems.id)
      expect(dvswitch.reload.host_id).to eq(host_esx.id)
      expect(dvswitch_archived.reload.ems_id).to eq(vmware_ems.id)
      expect(dvswitch_archived.reload.host_id).to eq(host_esx_archived.id)
      expect(dvswitch_without_assoc.reload.ems_id).to eq(vmware_ems.id)
      expect(dvswitch_without_assoc.reload.host_id).to eq(host_esx.id)

      # All switches except ManageIQ::Providers::Vmware::InfraManager::HostVirtualSwitch must stay the same
      expect(host_switch.reload.ems_id).to eq(nil)
      expect(host_switch.reload.host_id).to eq(nil)
      expect(host_switch_archived.reload.ems_id).to eq(vmware_ems.id)
      expect(host_switch_archived.reload.host_id).to eq(nil)
      expect(redhat_switch.reload.ems_id).to eq(nil)
      expect(redhat_switch.reload.host_id).to eq(nil)

      # Lenovo must be unaffected, since the switch relation is done a different way
      expect(physical_switch.reload.ems_id).to eq(lenovo_ems.id)
      expect(physical_switch.reload.host_id).to eq(nil)
      expect(physical_switch1.reload.ems_id).to eq(nil)
      expect(physical_switch1.reload.host_id).to eq(nil)
    end
  end
end