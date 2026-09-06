# DerpFest 16.2 Golden Reference Audit Report

- **Target Device**: enchilada (OnePlus 6)
- **Base Android**: Android 16 (SDK 36, QPR2)
- **Security Patch**: 2026-06-01
- **Package SHA256**: `35e57ac5211a1a98afa4dc3c04e102ed32f5e29d113ac757db003adcd8a48de8`

---

### 1. Boot Image & Kernel
- **boot.img SHA256**: `079f4847e6d74f9806a9b5eadc8a7b166cd775670bf7ded821e2eeeb02a58ec7`
- **boot.img Size**: 67108864 bytes
- **Kernel Version**: ``
- **Kernel Format**: `/tmp/unpacked_boot/kernel: gzip compressed data, max compression, from Unix, original size modulo 2^32 3437407`

#### Boot Header Info:
```
boot magic: ANDROID!
kernel_size: 22356281
kernel load address: 0x00008000
ramdisk size: 17012746
ramdisk load address: 0x01000000
second bootloader size: 0
second bootloader load address: 0x00000000
kernel tags load address: 0x00000100
page size: 4096
os version: 16.0.0
os patch level: 2026-06
boot image header version: 1
product name: 
command line args: androidboot.configfs=true androidboot.hardware=qcom androidboot.usbcontroller=a600000.dwc3 ehci-hcd.park=3 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 lpm_levels.sleep_disabled=1 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048
additional command line args: 
recovery dtbo size: 0
recovery dtbo offset: 0x0000000000000000
boot header size: 1648
```

---

### 2. DTBO Structure
- **dtbo.img SHA256**: `4e689374ba22d745451ba3a88bb679bdbeb85e88f3399dcc1e83e1bb90e4228c`
- **Entry Count**: 16
- **Header Magic**: `0xd7b7ab1e`
- **Page Size**: 4096

---

### 3. AVB / VBMeta
- **vbmeta.img SHA256**: `1dc98b5545ed8969574ea9248c5570d71fb7ee90a46b9c8cdd68c4c98b3e97a0`
```
N/A
```

---

### 4. FSTAB & First-Stage Mount Points
| Mount Point | Device | Type | Flags |
| :--- | :--- | :--- | :--- |
| `/system` | `/dev/block/by-name/system` | `ext4` | `wait,slotselect,avb,first_stage_mount` |
| `/vendor` | `/dev/block/by-name/vendor` | `ext4` | `wait,slotselect,avb,first_stage_mount` |
| `/metadata` | `/dev/block/by-name/logdump` | `ext4` | `wait,check,formattable,first_stage_mount` |
| `/mnt/vendor/op2` | `/dev/block/bootdevice/by-name/op2` | `ext4` | `wait,check` |
| `/data` | `/dev/block/bootdevice/by-name/userdata` | `ext4` | `wait,check,formattable,fileencryption=aes-256-xts:aes-256-cts:v2,quota,reservedsize=128M` |
| `/vendor/firmware_mnt` | `/dev/block/bootdevice/by-name/modem` | `vfat` | `wait,slotselect` |
| `/vendor/dsp` | `/dev/block/bootdevice/by-name/dsp` | `ext4` | `wait,slotselect` |
| `/mnt/vendor/persist` | `/dev/block/bootdevice/by-name/persist` | `ext4` | `wait` |
| `/vendor/bt_firmware` | `/dev/block/bootdevice/by-name/bluetooth` | `vfat` | `wait,slotselect` |
| `/storage/usbotg` | `/devices/platform/soc/a600000.ssusb/a600000.dwc3/xhci-hcd.*.auto*` | `auto` | `wait,voldmanaged=usbotg:auto` |
| `/misc` | `/dev/block/bootdevice/by-name/misc` | `emmc` | `defaults` |
| `none` | `/dev/block/zram0` | `swap` | `zramsize=1073741824` |

---

### 5. Init Services Discovered
- Total Services: 290
- `service oneplus_param_service /vendor/bin/hw/vendor.oneplus.hardware.param@1.0-service`
- `service qteeconnector-hal-1-0 /vendor/bin/hw/vendor.qti.hardware.qteeconnector@1.0-service`
- `service vendor.opcamera-mdm-1-0 /vendor/bin/hw/vendor.oneplus.hardware.CameraMDMHIDL@1.0-service`
- `service display-color-hal-1-0 /vendor/bin/hw/vendor.display.color@1.0-service`
- `service vendor.qti.hardware.display.allocator /vendor/bin/hw/vendor.qti.hardware.display.allocator-service`
- `service vendor.tri-state-key-calibrate /vendor/bin/tri-state-key-calibrate`
- `service vendor.health-default /vendor/bin/hw/android.hardware.health-service.qti`
- `service vendor.charger /vendor/bin/hw/android.hardware.health-service.qti --charger`
- `service vendor.sensors-hal-multihal /vendor/bin/hw/android.hardware.sensors-service.multihal`
- `service tui_comm-1-0 /vendor/bin/hw/vendor.qti.hardware.tui_comm@1.0-service-qti`
- `service vendor.ifaa_hal /vendor/bin/hw/vendor.oneplus.hardware.ifaa@2.0-service`
- `service vendor.usbgadget-hal /vendor/bin/hw/android.hardware.usb.gadget-service.qti`
- `service vendor.dataadpl /system/vendor/bin/adpl`
- `service vendor.qti.hardware.display.composer /vendor/bin/hw/vendor.qti.hardware.display.composer-service`
- `service gatekeeper-1-0 /vendor/bin/hw/android.hardware.gatekeeper@1.0-service-qti`
- `service wfdhdcphalservice /vendor/bin/wfdhdcphalservice`
- `service vendor.sensors /vendor/bin/sscrpcd sensorspd`
- `service vendor-qti-media-c2-hal-1-0 /vendor/bin/hw/vendor.qti.media.c2@1.0-service`
- `service wfdvndservice /vendor/bin/wfdvndservice`
- `service vendor.ims_rtp_daemon /vendor/bin/ims_rtp_daemon`
- *(and 270 more)*
