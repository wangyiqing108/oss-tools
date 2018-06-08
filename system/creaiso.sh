#!/bin/bash
ISO_DIR="/data/OS"
IMAGE_DIR="/data"
DATE=`date +%F-%H-%M-%S`
cd ${ISO_DIR}
rm -rf ${ISO_DIR}/repodata/*.gz
rm -rf ${ISO_DIR}/repodata/*.bz2
mv ${ISO_DIR}/repodata/b4* ${ISO_DIR}/repodata/c6-x86_64-comps.xml

declare -x discinfo=$(head -1 .discinfo) 
createrepo -g ${ISO_DIR}/repodata/*c6-x86_64-comps.xml ${ISO_DIR}
createrepo -u "media://$discinfo" -g  ${ISO_DIR}/repodata/*c6-x86_64-comps.xml  ${ISO_DIR}

mkisofs -R -T -r -l -z -d -allow-multidot -allow-leading-dots -no-bak -o ${IMAGE_DIR}/LetvOS_1.6.1_${DATE}.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table ${ISO_DIR}

echo "crate image : ${IMAGE_DIR}/LetvOS_1.6.1_${DATE}.iso"
cd ${IMAGE_DIR}
