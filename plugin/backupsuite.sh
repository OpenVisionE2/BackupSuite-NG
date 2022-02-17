#!/bin/sh

###############################################################################
#     FULL BACKUP UYILITY FOR ENIGMA2/OPENVISION, SUPPORTS VARIOUS MODELS     #
#                    MAKES A FULLBACKUP READY FOR FLASHING.                   #
###############################################################################

if [ -d "/usr/lib64" ]; then
	echo "multilib situation!"
	LIBDIR="/usr/lib64"
else
	LIBDIR="/usr/lib"
fi

if [ `mkdir -p /tmp/test && ls -e1 /tmp/test 2>/dev/null && echo Yes || echo No | cat` == "Yes" ]; then
	VISIONVERSION="7"
else
	VISIONVERSION="11"
fi

if [ $VISIONVERSION == "7" ]; then
	LS1="-e1"
	LS2="-el"
else
	LS1="-1"
	LS2="-l"
fi

## ADD A POSTRM ROUTINE TO ENSURE A CLEAN UNINSTALL
## This is normally added while building but despite several requests it isn't added yet
## So therefore this workaround.
POSTRM="/var/lib/opkg/info/enigma2-plugin-extensions-backupsuite.postrm"
if [ ! -f $POSTRM ] ; then
	echo "#!/bin/sh" > "$POSTRM"
	echo "rm -rf $LIBDIR/enigma2/python/Plugins/Extensions/BackupSuite" >> "$POSTRM"
	echo 'echo "Plugin removed!"' >> "$POSTRM"
	echo "exit 0" >> "$POSTRM"
	chmod 755 "$POSTRM"
fi
## END WORKAROUND

##TESTING IF PROGRAM IS RUN FROM COMMANDLINE OR CONSOLE, JUST FOR THE COLORS ##
if tty > /dev/null ; then		# Commandline
	RED='-e \e[00;31m'
	GREEN='-e \e[00;32m'
	YELLOW='-e \e[01;33m'
	BLUE='-e \e[01;34m'
	PURPLE='-e \e[01;31m'
	WHITE='-e \e[00;37m'
else							# On the STB
	RED='\c00??0000'
	GREEN='\c0000??00'
	YELLOW='\c00????00'
	BLUE='\c0000????'
	PURPLE='\c00?:55>7'
	WHITE='\c00??????'
fi
###################### FIRST DEFINE SOME PROGRAM BLOCKS #######################
############################# START LOGGING ###################################
log()
{
echo "$*" >> $LOGFILE
}
########################## DEFINE CLEAN-UP ROUTINE ############################
clean_up()
{
umount /tmp/bi/root > /dev/null 2>&1
rmdir /tmp/bi/root > /dev/null 2>&1
rmdir /tmp/bi > /dev/null 2>&1
rm -rf "$WORKDIR" > /dev/null 2>&1
}
###################### BIG OOPS!, HOLY SH... (SHELL SCRIPT :-))################
big_fail()
{
if [ -d $WORKDIR ] ; then
	log "FAIL!"
	log "Content so far of the working directory $WORKDIR "
	ls $LS2 $WORKDIR >> $LOGFILE
fi
clean_up
echo $RED
$SHOW "message15" 2>&1 | tee -a $LOGFILE # Image creation FAILED!
echo $WHITE
exit 0
}
############################ DEFINE IMAGE VERSION #############################
image_version()
{
echo "Backup = $BACKUPDATE"
echo "Version = $IMVER"
echo "Flashed = $FLASHED"
echo "Updated = $LASTUPDATE"
echo -n "Drivers = "
opkg list-installed | grep dvb-modules
echo "Enigma2 = $ENIGMA2DATE"
echo
echo $LINE
}
#################### CLEAN UP AND MAKE DESTINATION FOLDERS ####################
make_folders()
{
rm -rf "$MAINDEST"
log "Removed directory  = $MAINDEST"
mkdir -p "$MAINDEST"
log "Created directory  = $MAINDEST"
}
################ CHECK FOR THE NEEDED BINARIES IF THEY EXIST ##################
checkbinary()
{
if [ ! -f "$1" ] ; then {
	echo -n "$1 " ; $SHOW "message05"
	} 2>&1 | tee -a $LOGFILE
	big_fail
elif [ ! -x "$1" ] ; then
	{
	echo "Error: $1 " ; $SHOW "message35"
	} 2>&1 | tee -a $LOGFILE
	big_fail
fi
}
################### BACKUP MADE AND REPORTING SIZE ETC. #######################
backup_made()
{
{
echo $LINE
$SHOW "message10" ; echo "$MAINDEST" 	# USB Image created in:
$SHOW "message23"		# "The content of the folder is:"
if [ $VISIONVERSION == "7" ]; then
	ls "$MAINDEST" -e1rSh | sed 's/-.........    1//'
else
	ls "$MAINDEST" -1rSh | sed 's/-.........    1//'
fi
echo $LINE
if  [ $HARDDISK != 1 ]; then
	$SHOW "message11" ; echo "$EXTRA"		# and there is made an extra copy in:
	echo $LINE
fi
} 2>&1 | tee -a $LOGFILE
}
############################## END PROGRAM BLOCKS #############################
########################## DECLARATION OF VARIABLES ###########################
BACKUPDATE=`date +%Y.%m.%d_%H:%M`
DATE=`date +%Y%m%d_%H%M`
if [ -f "$LIBDIR/enigma2/python/Plugins/Extensions/BackupSuite/speed.txt" ] ; then
	ESTSPEED=`cat $LIBDIR/enigma2/python/Plugins/Extensions/BackupSuite/speed.txt`
	if [ $ESTSPEED -lt 50 ] ; then
		ESTSPEED="250"
	fi
else
	ESTSPEED="250"
fi
FLASHED=`date -r /etc/version +%Y.%m.%d_%H:%M`
ISSUE=`cat /etc/issue | grep . | tail -n 1 `
IMVER=${ISSUE%?????}
LASTUPDATE=`date -r /var/lib/opkg/status +%Y.%m.%d_%H:%M`
ENIGMA2DATE=`cat /tmp/enigma2version`
LOGFILE=/tmp/BackupSuite.log
MEDIA="$1"
MKFS=/usr/sbin/mkfs.ubifs
NANDDUMP=/usr/sbin/nanddump
START=$(date +%s)
TARGET="XX"
UBINIZE=/usr/sbin/ubinize
USEDsizebytes=`df -B 1 /usr/ | grep [0-9]% | tr -s " " | cut -d " " -f 3`
USEDsizekb=`df -k /usr/ | grep [0-9]% | tr -s " " | cut -d " " -f 3`
if [ -f "/var/lib/opkg/info/enigma2-plugin-extensions-backupsuite.control" ] ; then
	VERSION="Version: "`cat /var/lib/opkg/info/enigma2-plugin-extensions-backupsuite.control | grep "Version: " | cut -d "+" -f 2`
else
	VERSION=`$SHOW "message37"`
fi
WORKDIR="$MEDIA/bi"
######################### START THE LOGFILE $LOGFILE ##########################
echo -n "" > $LOGFILE
log "*** THIS BACKUP IS CREATED WITH THE BACKUPSUITE PLUGIN ***"
log "*****  https://github.com/OpenVisionE2/BackupSuite  ******"
log $LINE
log "Plugin version     = "`cat /var/lib/opkg/info/enigma2-plugin-extensions-backupsuite.control | grep "Version: " | cut -d "+" -f 2- | cut -d "-" -f1`
log "Backup media      = $MEDIA"
df -h "$MEDIA"  >> $LOGFILE
log $LINE
image_version >> $LOGFILE
log "Working directory  = $WORKDIR"
###### TESTING IF ALL THE BINARIES FOR THE BUILDING PROCESS ARE PRESENT #######
echo $RED
checkbinary $NANDDUMP
checkbinary $MKFS
checkbinary $UBINIZE
echo -n $WHITE
#############################################################################
# TEST IF RECEIVER IS SUPPORTED #
if [ -f /etc/modules-load.d/*dreambox-dvb-modules*.conf ] ; then
	log "It's a dreambox! Not compatible with this script."
	exit 1
else
	if [ -f /proc/enigma/model ] && [ -s /proc/enigma/model ] ; then
		log "Lets read enigma module proc entries"
		SEARCH=$( cat /proc/enigma/model )
		log "Model: $SEARCH"
		PLATFORM=$( cat /proc/enigma/platform )
		log "Platform: $PLATFORM"
		KERNELNAME=$( cat /proc/enigma/kernelfile )
		log "Kernel file: $KERNELNAME"
		MKUBIFS_ARGS=$( cat /proc/enigma/mkubifs )
		log "MKUBIFS: $MKUBIFS_ARGS"
		UBINIZE_ARGS=$( cat /proc/enigma/ubinize )
		log "UBINIZE: $UBINIZE_ARGS"
		ROOTNAME=$( cat /proc/enigma/rootfile )
		log "Root file: $ROOTNAME"
		ACTION=$( cat /proc/enigma/forcemode )
		log "Force: $ACTION"
		FOLDER=/$( cat /proc/enigma/imagedir )
		log "Image folder: $FOLDER"
		SHOWNAME=$( cat /proc/enigma/brand )
		log "Brand: $SHOWNAME"
		MTDPLACE=$( cat /proc/enigma/mtdkernel )
		log "MTD kernel: $MTDPLACE"
		ARCHITECTURE=$( cat /proc/enigma/architecture )
		log "Architecture: $ARCHITECTURE"
		SHORTARCH=$( echo "$ARCHITECTURE" | cut -c1-3 )
		SOCFAMILY=$( cat /proc/enigma/socfamily )
		log "SoC family: $SOCFAMILY"
		SHORTSOC=$( echo "$SOCFAMILY" | cut -c1-4 )
	else
		log "Multiboot situation? Lets read enigma.ko via modinfo -d"
		if [ ! -f /tmp/backupsuite-enigma.txt ] ; then
			find /lib/modules -type f -name "enigma.ko" -exec modinfo -d {} \; > /tmp/backupsuite-enigma.txt
			sleep 0.1
		fi
		ENIGMAMODULEDUMP=/tmp/backupsuite-enigma.txt
		SEARCH=$( cat $ENIGMAMODULEDUMP | grep "model" | sed '2d' | cut -d "=" -f 2- )
		log "Model: $SEARCH"
		PLATFORM=$( cat $ENIGMAMODULEDUMP | grep "platform" | cut -d "=" -f 2- )
		log "Platform: $PLATFORM"
		KERNELNAME=$( cat $ENIGMAMODULEDUMP | grep "kernelfile" | cut -d "=" -f 2- )
		log "Kernel file: $KERNELNAME"
		MKUBIFS_ARGS=$( cat $ENIGMAMODULEDUMP | grep "mkubifs" | cut -d "=" -f 2- )
		log "MKUBIFS: $MKUBIFS_ARGS"
		UBINIZE_ARGS=$( cat $ENIGMAMODULEDUMP | grep "ubinize" | cut -d "=" -f 2- )
		log "UBINIZE: $UBINIZE_ARGS"
		ROOTNAME=$( cat $ENIGMAMODULEDUMP | grep "rootfile" | cut -d "=" -f 2- )
		log "Root file: $ROOTNAME"
		ACTION=$( cat $ENIGMAMODULEDUMP | grep "forcemode" | cut -d "=" -f 2- )
		log "Force: $ACTION"
		FOLDER=$( cat $ENIGMAMODULEDUMP | grep "imagedir" | cut -d "=" -f 2- )
		log "Image folder: $FOLDER"
		SHOWNAME=$( cat $ENIGMAMODULEDUMP | grep "brand" | sed '2d' | cut -d "=" -f 2- )
		log "Brand: $SHOWNAME"
		MTDPLACE=$( cat $ENIGMAMODULEDUMP | grep "mtdkernel" | cut -d "=" -f 2- )
		log "MTD kernel: $MTDPLACE"
		ARCHITECTURE=$( cat $ENIGMAMODULEDUMP | grep "architecture" | cut -d "=" -f 2- )
		log "Architecture: $ARCHITECTURE"
		SHORTARCH=$( echo "$ARCHITECTURE" | cut -c1-3 )
		SOCFAMILY=$( cat $ENIGMAMODULEDUMP | grep "socfamily" | cut -d "=" -f 2- )
		log "SoC family: $SOCFAMILY"
		SHORTSOC=$( echo "$SOCFAMILY" | cut -c1-4 )
	fi
fi

EXTR1="/fullbackup_$SEARCH/$DATE"
EXTRA="$MEDIA$EXTR1$FOLDER"
if  [ $HARDDISK = 1 ]; then
	MAINDEST="$MEDIA$EXTR1$FOLDER"
	mkdir -p "$MAINDEST"
	log "Created directory  = $MAINDEST"
else
	MAINDEST="$MEDIA$FOLDER"
	mkdir -p "$MAINDEST"
	log "Created directory  = $MAINDEST"
fi

if [ $ROOTNAME = "rootfs.tar.bz2" ] ; then
	MKFS=/bin/tar
	checkbinary $MKFS
	BZIP2=/usr/bin/bzip2
	if [ ! -f "$BZIP2" ] ; then
		echo "$BZIP2 " ; $SHOW "message38"
		opkg update > /dev/null 2>&1
		opkg install bzip2 > /dev/null 2>&1
		checkbinary $MKFS
	fi
fi

log "Destination        = $MAINDEST"
log $LINE
############# START TO SHOW SOME INFORMATION ABOUT BRAND & MODEL ##############
echo -n $PURPLE
echo -n "$SHOWNAME $SEARCH " | tr  a-z A-Z		# Shows the receiver brand and model
$SHOW "message02"  			# BACKUP TOOL FOR MAKING A COMPLETE BACKUP
echo $BLUE
log "RECEIVER = $SHOWNAME $SEARCH "
log "MKUBIFS_ARGS = $MKUBIFS_ARGS"
log "UBINIZE_ARGS = $UBINIZE_ARGS"
echo "$VERSION"
echo $WHITE
############ CALCULATE SIZE, ESTIMATED SPEED AND SHOW IT ON SCREEN ############
$SHOW "message06" 	#"Some information about the task:"
if [ $ROOTNAME != "rootfs.tar.bz2" ] ; then
	KERNELHEX=`cat /proc/mtd | grep -w "kernel" | cut -d " " -f 2` # Kernelsize in Hex
else
	KERNELHEX=800000 # Not the real size (will be added later)
fi
KERNEL=$((0x$KERNELHEX))			# Total Kernel size in bytes
TOTAL=$(($USEDsizebytes+$KERNEL))	# Total ROOTFS + Kernel size in bytes
KILOBYTES=$(($TOTAL/1024))			# Total ROOTFS + Kernel size in KB
MEGABYTES=$(($KILOBYTES/1024))
{
echo -n "KERNEL" ; $SHOW "message04" ; printf '%6s' $(($KERNEL/1024)); echo ' KB'
echo -n "ROOTFS" ; $SHOW "message04" ; printf '%6s' $USEDsizekb; echo ' KB'
echo -n "=TOTAL" ; $SHOW "message04" ; printf '%6s' $KILOBYTES; echo " KB (= $MEGABYTES MB)"
} 2>&1 | tee -a $LOGFILE
if [ $ROOTNAME = "rootfs.tar.bz2" ] ; then
	ESTTIMESEC=$(($KILOBYTES/($ESTSPEED*3)))
else
	ESTTIMESEC=$(($KILOBYTES/$ESTSPEED))
fi
ESTMINUTES=$(( $ESTTIMESEC/60 ))
ESTSECONDS=$(( $ESTTIMESEC-(( 60*$ESTMINUTES ))))
echo $LINE
{
$SHOW "message03"  ; printf "%d.%02d " $ESTMINUTES $ESTSECONDS ; $SHOW "message25" # estimated time in minutes 
echo $LINE
} 2>&1 | tee -a $LOGFILE
####### WARNING IF THE IMAGESIZE GETS TOO BIG TO RESTORE ########
if [ -f /etc/openvision/smallflash ] ; then
	if [ $MEGABYTES -gt 62 ] ; then
	echo -n $RED
	$SHOW "message28" 2>&1 | tee -a $LOGFILE #Image probably too big to restore
	echo $WHITE
	fi
fi

if [ -f /etc/openvision/middleflash ] ; then
	if [ $MEGABYTES -gt 94 ] ; then
	echo -n $RED
	$SHOW "message28" 2>&1 | tee -a $LOGFILE #Image probably too big to restore
	echo $WHITE
	fi
fi
#=================================================================================
#exit 0  #USE FOR DEBUGGING/TESTING ###########################################
#=================================================================================
##################### PREPARING THE BUILDING ENVIRONMENT ######################
log "*** FIRST SOME HOUSEKEEPING ***"
rm -rf "$WORKDIR"		# GETTING RID OF THE OLD REMAINS IF ANY
log "Remove directory   = $WORKDIR"
mkdir -p "$WORKDIR"		# MAKING THE WORKING FOLDER WHERE EVERYTHING HAPPENS
log "Recreate directory = $WORKDIR"
mkdir -p /tmp/bi/root # this is where the complete content will be available
log "Create directory   = /tmp/bi/root"
sync
mount --bind / /tmp/bi/root # the complete root at /tmp/bi/root
## TEMPORARY WORKAROUND TO REMOVE
##      /var/lib/samba/private/msg.sock
## WHICH GIVES AN ERRORMESSAGE WHEN NOT REMOVED
if [ -d /tmp/bi/root/var/lib/samba/private/msg.sock ] ; then
	rm -rf /tmp/bi/root/var/lib/samba/private/msg.sock
fi
####################### START THE REAL BACKUP PROCESS ########################
############################# MAKING UBINIZE.CFG #############################
if [ $ROOTNAME != "rootfs.tar.bz2" ] ; then
	echo \[ubifs\] > "$WORKDIR/ubinize.cfg"
	echo mode=ubi >> "$WORKDIR/ubinize.cfg"
	echo image="$WORKDIR/root.ubi" >> "$WORKDIR/ubinize.cfg"
	echo vol_id=0 >> "$WORKDIR/ubinize.cfg"
	echo vol_type=dynamic >> "$WORKDIR/ubinize.cfg"
	echo vol_name=rootfs >> "$WORKDIR/ubinize.cfg"
	echo vol_flags=autoresize >> "$WORKDIR/ubinize.cfg"
	log $LINE
	log "UBINIZE.CFG CREATED WITH THE CONTENT:"
	cat "$WORKDIR/ubinize.cfg"  >> $LOGFILE
	touch "$WORKDIR/root.ubi"
	chmod 644 "$WORKDIR/root.ubi"
	log "--------------------------"
fi
############################## MAKING KERNELDUMP ##############################
log $LINE
$SHOW "message07" 2>&1 | tee -a $LOGFILE			# Create: kerneldump
log "Kernel resides on /dev/$MTDPLACE" 					# Just for testing purposes
if [ $SHORTARCH = "cor" -o $SHORTARCH = "arm" -o $SHORTARCH = "aar" ] ; then
	dd if=/dev/$MTDPLACE of=$WORKDIR/$KERNELNAME
else
	$NANDDUMP /dev/$MTDPLACE -qf "$WORKDIR/$KERNELNAME"	
fi
if [ -f "$WORKDIR/$KERNELNAME" ] ; then
	echo -n "Kernel dumped  :"  >> $LOGFILE
	ls $LS1 "$WORKDIR/$KERNELNAME" | sed 's/-r.*   1//' >> $LOGFILE
else
	log "$WORKDIR/$KERNELNAME NOT FOUND"
	big_fail
fi
#############################  MAKING ROOT.UBI(FS) ############################
$SHOW "message06a" 2>&1 | tee -a $LOGFILE		#Create: root.ubifs
log $LINE
if [ $ROOTNAME != "rootfs.tar.bz2" ] ; then
	$MKFS -r /tmp/bi/root -o "$WORKDIR/root.ubi" $MKUBIFS_ARGS
	if [ -f "$WORKDIR/root.ubi" ] ; then
		echo -n "ROOT.UBI MADE  :" >> $LOGFILE
		ls $LS1 "$WORKDIR/root.ubi" | sed 's/-r.*   1//' >> $LOGFILE
		UBISIZE=`cat "$WORKDIR/root.ubi" | wc -c`
		if [ "$UBISIZE" -eq 0 ] ; then
			$SHOW "message39" 2>&1 | tee -a $LOGFILE
			big_fail
		fi
	else
		log "$WORKDIR/root.ubi NOT FOUND"
		big_fail
	fi
	log $LINE
	echo "Start UBINIZING" >> $LOGFILE
	$UBINIZE -o "$WORKDIR/$ROOTNAME" $UBINIZE_ARGS "$WORKDIR/ubinize.cfg" >/dev/null
	chmod 644 "$WORKDIR/$ROOTNAME"
	if [ -f "$WORKDIR/$ROOTNAME" ] ; then
		echo -n "$ROOTNAME MADE:" >> $LOGFILE
		ls $LS1 "$WORKDIR/$ROOTNAME" | sed 's/-r.*   1//' >> $LOGFILE
	else
		echo "$WORKDIR/$ROOTNAME NOT FOUND"  >> $LOGFILE
		big_fail
	fi
	echo
else
	if [ $VISIONVERSION == "7" ]; then
		$MKFS -cf $WORKDIR/rootfs.tar -C /tmp/bi/root --exclude=/var/nmbd/* .
	else
		$MKFS -cf $WORKDIR/rootfs.tar -C /tmp/bi/root .
	fi
	$BZIP2 $WORKDIR/rootfs.tar
fi
############################ ASSEMBLING THE IMAGE #############################
make_folders
mv -f "$WORKDIR/$ROOTNAME" "$MAINDEST/$ROOTNAME"
mv -f "$WORKDIR/$KERNELNAME" "$MAINDEST/$KERNELNAME"
if [ $ACTION = "no" ] ; then
	if [ $SHORTSOC = "hisi" ] ; then
		echo "Rename unforce_$SEARCH.txt to force_$SEARCH.txt and move it to the root of your usb-stick" > "$MAINDEST/unforce_$SEARCH.txt";
	elif [ $SHOWNAME = "vuplus" ] ; then
		echo "rename this file to 'force.update' to force an update without confirmation" > "$MAINDEST/reboot.update"
	else
		echo "rename this file to 'force' to force an update without confirmation" > "$MAINDEST/noforce";
	fi
elif [ $ACTION = "yes" ] ; then
	if [ $SHORTSOC = "hisi" ] ; then
		echo "Rename force_$SEARCH.txt to unforce_$SEARCH.txt and move it to the root of your usb-stick" > "$MAINDEST/force_$SEARCH.txt";
	elif [ $SHOWNAME = "vuplus" ] ; then
		echo "rename this file to 'reboot.update' to not force an update without confirmation" > "$MAINDEST/force.update"
	else
		echo "rename this file to 'noforce' to not force an update without confirmation" > "$MAINDEST/force";
	fi
fi
image_version > "$MAINDEST/imageversion"
if [ -f /boot/initrd_run.bin ] ; then
	cp -f /boot/initrd_run.bin "$MAINDEST/initrd_run.bin"
fi
if [ -f /usr/share/enigma2/receiver/burn.bat ] ; then
	cp -f /usr/share/enigma2/receiver/burn.bat "$MAINDEST/burn.bat"
fi
if [ $PLATFORM = "zgemmahisi3798mv200" -o $PLATFORM = "zgemmahisi3716mv430" ] ; then
	log "Zgemma HiSilicon found, we need to copy more files for flashing later!"
	dd if=/dev/mtd0 of=$MAINDEST/fastboot.bin > /dev/null 2>&1
	dd if=/dev/mtd1 of=$MAINDEST/bootargs.bin > /dev/null 2>&1
	cp -fr "$MAINDEST/fastboot.bin" "$MEDIA/zgemma/fastboot.bin" > /dev/null 2>&1
	cp -fr "$MAINDEST/bootargs.bin" "$MEDIA/zgemma/bootargs.bin" > /dev/null 2>&1
	dd if=/dev/mtd2 of=$MAINDEST/baseparam.bin > /dev/null 2>&1
	dd if=/dev/mtd3 of=$MAINDEST/pq_param.bin > /dev/null 2>&1
fi
if  [ $HARDDISK != 1 ]; then
	mkdir -p "$EXTRA"
	echo "Created directory  = $EXTRA" >> $LOGFILE
	cp -fr "$MAINDEST" "$EXTRA" 	#copy the made backup to images
fi
if [ -f "$MAINDEST/$ROOTNAME" -a -f "$MAINDEST/$KERNELNAME" ] ; then
		backup_made
		$SHOW "message14" 			# Instructions on how to restore the image.
		echo $LINE
else
	big_fail
fi
#################### CHECKING FOR AN EXTRA BACKUP STORAGE #####################
if  [ $HARDDISK = 1 ]; then						# looking for a valid usb-stick
	for candidate in `cut -d ' ' -f 2 /proc/mounts | grep '^/media/'`
	do
		if [ -f "${candidate}/"*[Bb][Aa][Cc][Kk][Uu][Pp][Ss][Tt][Ii][Cc][Kk]* ]
		then
		TARGET="${candidate}"
		fi
	done
	if [ "$TARGET" != "XX" ] ; then
		echo -n $GREEN
		$SHOW "message17" 2>&1 | tee -a $LOGFILE 	# Valid USB-flashdrive detected, making an extra copy
		echo $LINE
		TOTALSIZE="$(df -h "$TARGET" | tail -n 1 | awk {'print $2'})"
		FREESIZE="$(df -h "$TARGET" | tail -n 1 | awk {'print $4'})"
		{
		$SHOW "message09" ; echo -n "$TARGET ($TOTALSIZE, " ; $SHOW "message16" ; echo "$FREESIZE)"
		} 2>&1 | tee -a $LOGFILE
		rm -rf "$TARGET$FOLDER"
		mkdir -p "$TARGET$FOLDER"
		cp -fr "$MAINDEST/." "$TARGET$FOLDER"
		echo $LINE >> $LOGFILE
		echo "MADE AN EXTRA COPY IN: $TARGET" >> $LOGFILE
		df -h "$TARGET"  >> $LOGFILE
		$SHOW "message19" 2>&1 | tee -a $LOGFILE	# Backup finished and copied to your USB-flashdrive
	else
		$SHOW "message40" >> $LOGFILE
	fi
sync
fi
######################### END OF EXTRA BACKUP STORAGE #########################
################## CLEANING UP AND REPORTING SOME STATISTICS ##################
clean_up
END=$(date +%s)
DIFF=$(( $END - $START ))
MINUTES=$(( $DIFF/60 ))
SECONDS=$(( $DIFF-(( 60*$MINUTES ))))
echo -n $YELLOW
{
$SHOW "message24"  ; printf "%d.%02d " $MINUTES $SECONDS ; $SHOW "message25"
} 2>&1 | tee -a $LOGFILE
if [ $VISIONVERSION == "7" ]; then
	ROOTSIZE=`ls "$MAINDEST" -e1S | grep $ROOTNAME | awk {'print $3'} `
	KERNELSIZE=`ls "$MAINDEST" -e1S | grep $KERNELNAME | awk {'print $3'} `
else
	ROOTSIZE=`ls "$MAINDEST" -lS | grep $ROOTNAME | awk {'print $5'} `
	KERNELSIZE=`ls "$MAINDEST" -lS | grep $KERNELNAME | awk {'print $5'} `
fi
TOTALSIZE=$((($ROOTSIZE+$KERNELSIZE)/1024))
SPEED=$(( $TOTALSIZE/$DIFF ))
echo $SPEED > $LIBDIR/enigma2/python/Plugins/Extensions/BackupSuite/speed.txt
echo $LINE >> $LOGFILE
# "Back up done with $SPEED KB per second"
{
$SHOW "message26" ; echo -n "$SPEED" ; $SHOW "message27"
} 2>&1 | tee -a $LOGFILE
#### ADD A LIST OF THE INSTALLED PACKAGES TO THE BackupSuite.LOG ####
echo $LINE >> $LOGFILE
echo $LINE >> $LOGFILE
$SHOW "message41" >> $LOGFILE
echo "--------------------------------------------" >> $LOGFILE
opkg list-installed >> $LOGFILE
######################## COPY LOGFILE TO MAINDESTINATION ######################
echo -n $WHITE
cp -f $LOGFILE "$MAINDEST"
if  [ $HARDDISK != 1 ]; then
	cp -f $LOGFILE "$MEDIA$EXTR1"
	if [ -f "$MEDIA$EXTR1$FOLDER/imageversion" ]; then
		mv -f "$MEDIA$EXTR1$FOLDER"/imageversion "$MEDIA$EXTR1"
	fi
else
	mv -f "$MAINDEST"/BackupSuite.log "$MEDIA$EXTR1"
	cp -f "$MAINDEST"/imageversion "$MEDIA$EXTR1"
fi
if [ "$TARGET" != "XX" ] ; then
	cp -f $LOGFILE "$TARGET$FOLDER"
fi
exit
############### END OF PROGRAMM ################
