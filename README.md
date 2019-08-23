# USB Bootable CentOS with custom Kickstart

The script creates an CentOS based ISO (with a custom kickstart) that can be burned to a USB.

## Limitations

* The ISO created **requires Legacy Boot support on your Host**, it will not work with UEFI or Secure Boot systems
* This has only been tested with CentOS-7-x86_64-Minimal-1810, mileage may vary with other ISOs
* The solution assumes that you will run this script on a CentOS 7 host (it uses binaries downloaded via yum)

## Running

The script can be executed as below:

```sh
./create.sh <iso> <kickstart file>
```

The generated ISO will be available in the created ./tmp directory, the ISO name can be overriden with the env variable GENISO

You can create a bootable USB using the ISO on the same CentOS host as follows, ensure that you **correctly identify** the partition where the USB is mounted, in the example below sdb:

```sh
$ umount /dev/sdb1
$ mkfs.vfat /dev/sdb1
$ dd if=tmp/*.iso of=/dev/sdb1
```


# Credits

The script is based off the article written by Siyuan Liu

See here for the details - https://shawnliu.me/post/kickstart-centos-7-installation/ 