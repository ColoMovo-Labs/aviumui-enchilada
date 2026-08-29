# sync rom
repo init --depth=1 --no-repo-verify -u https://github.com/AviumUI/android_manifests -b avium-16.2 -g default,-mips,-darwin,-notdefault --git-lfs
git clone https://github.com/ColoMovo/aviumui-enchilada-manifests.git --depth 1 .repo/local_manifests
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j8

# build rom
source build/envsetup.sh
lunch lineage_enchilada-bp4a-userdebug
export TZ=Asia/Shanghai
m bacon

# upload rom
rclone copy out/target/product/$(grep unch $CIRRUS_WORKING_DIR/build_rom.sh -m 1 | cut -d ' ' -f 2 | cut -d _ -f 2 | cut -d - -f 1)/*.zip cirrus:$(grep unch $CIRRUS_WORKING_DIR/build_rom.sh -m 1 | cut -d ' ' -f 2 | cut -d _ -f 2 | cut -d - -f 1) -P
