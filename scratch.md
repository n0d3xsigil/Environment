This is just for bits that I have missed, I will need to revisit and document on the next round

- Bluetooth (install, enable, scan, connect, trust)
- Screen resolution( arandr, xinitrc etc..)

more stuff

Build the VM environment

```shell
sudo pacman -S qemu virt-manager virt-viewer dnsmasq bridge-utils openbsd-netcat libguestfs
```



enable the `LibVirtD` service

```shell
[archichub@archichub ~]$ sudo systemctl enable --now libvirtd
[sudo] password for archichub:
Created symlink '/etc/systemd/system/multi-user.target.wants/libvirtd.service' → '/usr/lib/systemd/system/libvirtd.service'.
Created symlink '/etc/systemd/system/sockets.target.wants/virtlockd.socket' → '/usr/lib/systemd/system/virtlockd.socket'.
Created symlink '/etc/systemd/system/sockets.target.wants/virtlogd.socket' → '/usr/lib/systemd/system/virtlogd.socket'.
Created symlink '/etc/systemd/system/sockets.target.wants/libvirtd.socket' → '/usr/lib/systemd/system/libvirtd.socket'.
Created symlink '/etc/systemd/system/sockets.target.wants/libvirtd-ro.socket' → '/usr/lib/systemd/system/libvirtd-ro.socket'.
Created symlink '/etc/systemd/system/sockets.target.wants/libvirtd-admin.socket' → '/usr/lib/systemd/system/libvirtd-admin.socket'.
Created symlink '/etc/systemd/system/sockets.target.wants/virtlockd-admin.socket' → '/usr/lib/systemd/system/virtlockd-admin.socket'.
Created symlink '/etc/systemd/system/sockets.target.wants/virtlogd-admin.socket' → '/usr/lib/systemd/system/virtlogd-admin.socket'.
```

Add your user to the libvirt group to allow running without root permissions

```shell
[archichub@archichub ~]$ sudo usermod -a -G libvirt $(whoami)
[sudo] password for archichub:
```

Enable user access to networks

```shell
[archichub@archichub ~]$ sudo vim /etc/libvirt/qemu.conf
[sudo] password for archichub:
```

Find `#user = "libvirt-qemu` and change it to `user = "archibold"`
Find `#group = "libvirt-qemu` and change it to `group = "libvirt"`


Example result
```text
# Some examples of valid values are:
#
#       user = "qemu"   # A user named "qemu"
#       user = "+0"     # Super user (uid=0)
#       user = "100"    # A user named "100" or a user with uid=100
#
#user = "libvirt-qemu"
user = "archichub"

# The group for QEMU processes run by the system instance. It can be
# specified in a similar way to user.
#group = "libvirt-qemu"
group = "libvirt"
```


Restart the `libvirtd` service to pick up the changes

```shell
[archichub@archichub ~]$ sudo systemctl restart libvirtd
[sudo] password for archichub:
[archichub@archichub ~]$
```


We need to verify KVM support

```shell
[archichub@archichub ~]$ cat /proc/cpuinfo  | grep -E "(vmx|svm)"
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp vnmi pku ospke md_clear flush_l1d arch_capabilities
vmx flags       : vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_violation_ve ept_mode_based_exec
```

I'm going to hazard a guess and say this is per cpu core rather than per cpu. Anyway `VMX` is present.


Let's check that the kvm module is loaded 

```shell
[archichub@archichub ~]$ lsmod | grep kvm
kvm_intel             434176  0
kvm                  1388544  1 kvm_intel
irqbypass              12288  1 kvm
```

Ensure `kvm_intel` loads each time

```shell
[archichub@archichub ~]$ echo "kvm_intel" | sudo tee /etc/modules-load.d/kvm.conf
[sudo] password for archichub:
kvm_intel
```

### basic network

check the status of the default network

```shell
[archichub@archichub ~]$ sudo virsh net-list --all
[sudo] password for archichub:
setlocale: No such file or directory
 Name      State      Autostart   Persistent
----------------------------------------------
 default   inactive   no          yes
```

The `default` connection is **inactive**. Start it

```shell
[archichub@archichub ~]$ sudo virsh net-start default
[sudo] password for archichub:
setlocale: No such file or directory
Network default started
```


Let's have it auto start

```shell
[archichub@archichub ~]$ sudo virsh net-autostart default
[sudo] password for archichub:
setlocale: No such file or directory
Network default marked as autostarted
```

We can now start `virt-manager` and check it starts okay

- `[trust]` it did

Add `virt-manager` to the openbox autostart file

```shell
[archichub@archichub ~]$ echo "virt-manager &" >> ~/.config/openbox/autostart; cat ~/.config/openbox/autostart
# Set wallpaper
feh --bg-fill /home/archichub/Pictures/wallpaper.jpg
virt-manager &
```

## Bluetooth

- [ ] Include `bluez` into base build
- [ ] Include `bluez-utils`into base build


### Bluetooth - install
Otherwise install manually

```shell
[archibold@archibold ~]$ sudo pacman -S bluez bluez-utils
[sudo] password for archibold: 
resolving dependencies...
looking for conflicting packages...

Packages (2) bluez-5.83-1  bluez-utils-5.83-1

Total Download Size:   1.51 MiB
Total Installed Size:  4.83 MiB

:: Proceed with installation? [Y/n] 
:: Retrieving packages...
 bluez-utils-5.83-1-x86_64  979.0 KiB  3.90 MiB/s 00:00 [##############################] 100%
 bluez-5.83-1-x86_64        565.5 KiB  2.05 MiB/s 00:00 [##############################] 100%
 Total (2/2)               1544.5 KiB  5.01 MiB/s 00:00 [##############################] 100%
(2/2) checking keys in keyring                          [##############################] 100%
(2/2) checking package integrity                        [##############################] 100%
(2/2) loading package files                             [##############################] 100%
(2/2) checking for file conflicts                       [##############################] 100%
(2/2) checking available disk space                     [##############################] 100%
:: Processing package changes...
(1/2) installing bluez                                  [##############################] 100%
(2/2) installing bluez-utils                            [##############################] 100%
Optional dependencies for bluez-utils
    ell: for btpclient [installed]
:: Running post-transaction hooks...
(1/4) Reloading system manager configuration...
(2/4) Reloading user manager configuration...
(3/4) Arming ConditionNeedsUpdate...
(4/4) Reloading system bus configuration...
```



Enable the bluetooth service to ensure it works after reboot

```shell
[archibold@archibold ~]$ sudo systemctl enable --now bluetooth
[sudo] password for archibold: 
Created symlink '/etc/systemd/system/dbus-org.bluez.service' → '/usr/lib/systemd/system/bluetooth.service'.
Created symlink '/etc/systemd/system/bluetooth.target.wants/bluetooth.service' → '/usr/lib/systemd/system/bluetooth.service'.
```



### Bluetooth - Pair device

Then we can use `bluetoothctl` to pair new devices

```shell
[archibold@archibold ~]$ bluetoothctl
[NEW] Media /org/bluez/hci0 
	SupportedUUIDs: 0000110a-0000-1000-8000-53a36e356757
	SupportedUUIDs: 0000110b-0000-1000-8000-53a36e356757
Agent registered
[CHG] Controller da:db:29:28:41:d3 Pairable: yes
hci0 new_settings: powered bondable ssp br/edr le secure-conn wide-band-speech 
[bluetoothctl]>
```



Once in the bluetooth control utility you can turn on the radio.

```shell
[bluetoothctl]> power on
Changing power on succeeded
```



This next step may or may not be required. Documentation says to do it but I alway ss get the _`Agent is already registered`_ message. So, next time I may very well skip this step.

```shell
[bluetoothctl]> agent on
Agent is already registered
```



Use the default agent

```shell
[bluetoothctl]> default-agent
Default agent request successful
```



Then turn on scan to find devices

```[bluetoothctl]> scan on
SetDiscoveryFilter success
Discovery started
[CHG] Controller da:db:29:28:41:d3 Discovering: yes
[NEW] Device 5c:c8:2b:12:1d:14 5c-c8-2b-12-1d-14
[NEW] Device 09:89:93:70:f0:d0 MX Anywhere 2S
```



I want to connect to the **MX Anywhere 2S** device so issue `pair`

```
[bluetoothctl]> pair 09:89:93:70:f0:d0
Attempting to pair with 09:89:93:70:f0:d0
[CHG] Device 09:89:93:70:f0:d0 Connected: yes
[CHG] Device 09:89:93:70:f0:d0 Bonded: yes
[CHG] Device 09:89:93:70:f0:d0 WakeAllowed: yes
[CHG] Device 09:89:93:70:f0:d0 UUIDs: 00001800-0000-1000-8000-53a36e356757
[CHG] Device 09:89:93:70:f0:d0 UUIDs: 00001801-0000-1000-8000-53a36e356757
[CHG] Device 09:89:93:70:f0:d0 UUIDs: 0000180a-0000-1000-8000-53a36e356757
[CHG] Device 09:89:93:70:f0:d0 UUIDs: 0000180f-0000-1000-8000-53a36e356757
[CHG] Device 09:89:93:70:f0:d0 UUIDs: 00001812-0000-1000-8000-53a36e356757
[CHG] Device 09:89:93:70:f0:d0 UUIDs: 00010000-0000-1000-8000-dfadb42e01cc
[CHG] Device 09:89:93:70:f0:d0 ServicesResolved: yes
[CHG] Device 09:89:93:70:f0:d0 Paired: yes
[NEW] Primary Service (Handle 0x0001)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service0001
	00001800-0000-1000-8000-53a36e356757
	Generic Access Profile
[NEW] Characteristic (Handle 0x0002)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service0001/char0002
	00002a00-0000-1000-8000-53a36e356757
	Device Name
[NEW] Characteristic (Handle 0x0004)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service0001/char0004
	00002a01-0000-1000-8000-53a36e356757
	Appearance
[NEW] Characteristic (Handle 0x0006)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service0001/char0006
	00002a04-0000-1000-8000-53a36e356757
	Peripheral Preferred Connection Parameters
[NEW] Primary Service (Handle 0x0008)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service0008
	00001801-0000-1000-8000-53a36e356757
	Generic Attribute Profile
[NEW] Characteristic (Handle 0x0009)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service0008/char0009
	00002a05-0000-1000-8000-53a36e356757
	Service Changed
[NEW] Descriptor (Handle 0x000b)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service0008/char0009/desc000b
	00002902-0000-1000-8000-53a36e356757
	Client Characteristic Configuration
[NEW] Primary Service (Handle 0x000c)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service000c
	0000180a-0000-1000-8000-53a36e356757
	Device Information
[NEW] Characteristic (Handle 0x000d)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service000c/char000d
	00002a29-0000-1000-8000-53a36e356757
	Manufacturer Name String
[NEW] Characteristic (Handle 0x000f)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service000c/char000f
	00002a24-0000-1000-8000-53a36e356757
	Model Number String
[NEW] Characteristic (Handle 0x0011)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service000c/char0011
	00002a25-0000-1000-8000-53a36e356757
	Serial Number String
[NEW] Characteristic (Handle 0x0013)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service000c/char0013
	00002a27-0000-1000-8000-53a36e356757
	Hardware Revision String
[NEW] Characteristic (Handle 0x0015)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service000c/char0015
	00002a26-0000-1000-8000-53a36e356757
	Firmware Revision String
[NEW] Characteristic (Handle 0x0017)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service000c/char0017
	00002a28-0000-1000-8000-53a36e356757
	Software Revision String
[NEW] Characteristic (Handle 0x0019)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service000c/char0019
	00002a50-0000-1000-8000-53a36e356757
	PnP ID
[NEW] Primary Service (Handle 0x001b)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001b
	0000180f-0000-1000-8000-53a36e356757
	Battery Service
[NEW] Characteristic (Handle 0x001c)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001b/char001c
	00002a19-0000-1000-8000-53a36e356757
	Battery Level
[NEW] Descriptor (Handle 0x001e)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001b/char001c/desc001e
	00002902-0000-1000-8000-53a36e356757
	Client Characteristic Configuration
[NEW] Primary Service (Handle 0x001f)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f
	00001812-0000-1000-8000-53a36e356757
	Human Interface Device
[NEW] Characteristic (Handle 0x0020)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0020
	00002a4a-0000-1000-8000-53a36e356757
	HID Information
[NEW] Characteristic (Handle 0x0022)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0022
	00002a22-0000-1000-8000-53a36e356757
	Boot Keyboard Input Report
[NEW] Descriptor (Handle 0x0024)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0022/desc0024
	00002902-0000-1000-8000-53a36e356757
	Client Characteristic Configuration
[NEW] Characteristic (Handle 0x0025)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0025
	00002a32-0000-1000-8000-53a36e356757
	Boot Keyboard Output Report
[NEW] Characteristic (Handle 0x0027)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0027
	00002a33-0000-1000-8000-53a36e356757
	Boot Mouse Input Report
[NEW] Descriptor (Handle 0x0029)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0027/desc0029
	00002902-0000-1000-8000-53a36e356757
	Client Characteristic Configuration
[NEW] Characteristic (Handle 0x002a)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char002a
	00002a4b-0000-1000-8000-53a36e356757
	Report Map
[NEW] Characteristic (Handle 0x002c)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char002c
	00002a4d-0000-1000-8000-53a36e356757
	Report
[NEW] Descriptor (Handle 0x002e)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char002c/desc002e
	00002902-0000-1000-8000-53a36e356757
	Client Characteristic Configuration
[NEW] Descriptor (Handle 0x002f)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char002c/desc002f
	00002908-0000-1000-8000-53a36e356757
	Report Reference
[NEW] Characteristic (Handle 0x0030)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0030
	00002a4d-0000-1000-8000-53a36e356757
	Report
[NEW] Descriptor (Handle 0x0032)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0030/desc0032
	00002902-0000-1000-8000-53a36e356757
	Client Characteristic Configuration
[NEW] Descriptor (Handle 0x0033)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0030/desc0033
	00002908-0000-1000-8000-53a36e356757
	Report Reference
[NEW] Characteristic (Handle 0x0034)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0034
	00002a4d-0000-1000-8000-53a36e356757
	Report
[NEW] Descriptor (Handle 0x0036)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0034/desc0036
	00002902-0000-1000-8000-53a36e356757
	Client Characteristic Configuration
[NEW] Descriptor (Handle 0x0037)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0034/desc0037
	00002908-0000-1000-8000-53a36e356757
	Report Reference
[NEW] Characteristic (Handle 0x0038)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0038
	00002a4d-0000-1000-8000-53a36e356757
	Report
[NEW] Descriptor (Handle 0x003a)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char0038/desc003a
	00002908-0000-1000-8000-53a36e356757
	Report Reference
[NEW] Characteristic (Handle 0x003b)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char003b
	00002a4c-0000-1000-8000-53a36e356757
	HID Control Point
[NEW] Characteristic (Handle 0x003d)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service001f/char003d
	00002a4e-0000-1000-8000-53a36e356757
	Protocol Mode
[NEW] Primary Service (Handle 0x003f)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service003f
	00010000-0000-1000-8000-dfadb42e01cc
	Vendor specific
[NEW] Characteristic (Handle 0x0040)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service003f/char0040
	00010001-0000-1000-8000-dfadb42e01cc
	Vendor specific
[NEW] Descriptor (Handle 0x0042)
	/org/bluez/hci0/dev_09_89_93_70_f0_d0/service003f/char0040/desc0042
	00002902-0000-1000-8000-53a36e356757
	Client Characteristic Configuration
Pairing successful
[CHG] Device 09:89:93:70:f0:d0 Modalias: usb:v046DpB01Af4312
```



Next we want to trust the device

```shell
[MX Anywhere 2S]> trust 09:89:93:70:f0:d0
[CHG] Device 09:89:93:70:f0:d0 Trusted: yes
Changing 09:89:93:70:f0:d0 trust succeeded
```



And finally, connect to the device

```shell
[MX Anywhere 2S]> connect 09:89:93:70:f0:d0
Attempting to connect to 09:89:93:70:f0:d0
Connection successful
```



Repeat this process for each device you would like to connect using bluetooth.





