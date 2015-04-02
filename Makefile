prepare:
	rm -rf mkdir mopidy_chroot
	test -s vivid-core-armhf.tar.gz || { wget http://cdimage.ubuntu.com/ubuntu-core/daily/current/vivid-core-armhf.tar.gz; }
	mkdir mopidy_chroot
	tar xvf vivid-core-armhf.tar.gz -C mopidy_chroot/ || true

pre: 
	test -s /usr/bin/qemu-arm-static || { echo "Please install qemu-arm-static! Exiting..."; exit 1; }
	cp -f /usr/bin/qemu-arm-static mopidy_chroot/usr/bin
	chroot mopidy_chroot mount -t proc /proc /proc
	chroot mopidy_chroot mount -t sysfs sysfs /sys
	@mount --rbind /dev mopidy_chroot/dev/ || true
	@mount --rbind /run mopidy_chroot/run/ || true
	
post:
	chroot mopidy_chroot umount /sys
	chroot mopidy_chroot umount /proc
	@umount -lf mopidy_chroot/dev/ || true
	@umount -lf mopidy_chroot/run/ || true
	rm mopidy_chroot/usr/bin/qemu-arm-static || true

deboostrap:
	echo "nameserver 8.8.8.8" > mopidy_chroot/etc/resolv.conf
	echo "nameserver 8.8.4.4" >> mopidy_chroot/etc/resolv.conf
	chroot mopidy_chroot /usr/bin/apt-get install python -yq

playbook:
	ANSIBLE_REMOTE_TEMP=/tmp ansible-playbook -c chroot -i "$(shell pwd)/mopidy_chroot," mopidy.yml

mopidy: pre deboostrap playbook post

image:
	tar cfJ mopidy-core.tar.xz  mopidy_chroot/
