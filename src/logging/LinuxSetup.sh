#!/bin/bash

#********************************************************************
#            Copyright (C) Ming Fangsen Technologies, 2012-3
#
#  #FileName                : LinuxSetup.sh
#  #Writter                 : Ming Fangsen
#  #Sub Modules             :
#  #Mudule Name             : INIT
#  #Language                : shell
#  #Environment             : 2285 + Suse Linux SP1
#  #First Release Date      : 2012-3-15
#  #Description             : the main installation program
#********************************************************************
LOCAL_SCRIPT_PATH=/usr/Euler/project
export LOCAL_SCRIPT_PATH

source $LOCAL_SCRIPT_PATH/util/GlobalVariables.sh

###########module variables#############
INIT_SETUPOS_SCRIPT=$LOCAL_SCRIPT_PATH/install/setupOS.sh
INIT_MKFIRSTBOOT_SCRIPT=$LOCAL_SCRIPT_PATH/firstboot/mkfirstboot.sh

INIT_MODULES=$LOCAL_SCRIPT_PATH/init/InitModules.sh

#define finish usb installation script name
INIT_FINSH_USB_INSTALL=$LOCAL_SCRIPT_PATH/firstboot/finshUsbInstall.sh
INIT_UI_SCRIPT=$LOCAL_SCRIPT_PATH/ui/main_text.py
INIT_UIPROGRESS_SCRIPT=$LOCAL_SCRIPT_PATH/ui/progress_text.py
INIT_HDCHK_SCRIPT=$LOCAL_SCRIPT_PATH/modules/hdcheck.sh
INIT_UPLOAD_SCRIPT=$LOCAL_SCRIPT_PATH/load/fileupload.sh
INIT_GETDISKLIST_SCRIPT=$LOCAL_SCRIPT_PATH/disk/getdisklist.sh
AFTER_INSSUCC_HOOK=$LOCAL_ADDONSCRIPT_PATH/after_inssucc_hook
BEFORE_MKFIRSTBOOT_HOOK=$LOCAL_ADDONSCRIPT_PATH/before_mkfirstboot_hook
AFTER_INSFAIL_HOOK=$LOCAL_ADDONSCRIPT_PATH/after_insfail_hook
BEFORE_INSTALL_HOOK=$LOCAL_ADDONSCRIPT_PATH/before_install_hook
BEFORE_REBOOT_HOOK=$LOCAL_ADDONSCRIPT_PATH/before_reboot_hook

#########################################################
#    Description: upload log to remote server
#    Return:      0-success, 1-failed
#########################################################
function INIT_Upload_LOG()
{
    #check if log file does exist
    if [ ! -f "$LOG_FILE" ];then
        g_LOG_Warn "log file dose not exist."
        return 1
    fi

    local base_Log_Path=/var/log
    local filedate="`date +%Y%m%d%H%M%S`"
    local mac=`ifconfig -a | grep -i $NET_DEVICE | awk '{print $5}'`
    mac=`echo $mac | sed 's/:/-/g'`
    local target_LogPath=${filedate}_${mac}_OSLOG
    local local_OS_LogPath=${LOCAL_DISK_PATH}/var/log/miniOS/

    if [ `echo $INSTALL_MEDIA | egrep -i "^PXE$"` ];then
        #create dir
        cd $base_Log_Path
        if [ -d $target_LogPath ];then
            rm -rf $target_LogPath > $OTHER_TTY 2>&1
        fi
        mkdir $target_LogPath
        #recopy log file
        cp $LOG_FILE $target_LogPath > $OTHER_TTY 2>&1
        if [ -f /var/log/miniOS_dmesg ];then
            cp /var/log/miniOS_dmesg $target_LogPath/dmesg  > $OTHER_TTY 2>&1
        fi
        #copy user's rpm setuplog
        if [ -d $local_OS_LogPath ];then
            cp $local_OS_LogPath/* $target_LogPath > $OTHER_TTY 2>&1
        fi

        #compress miniOS log
        tar -zcf ${target_LogPath}.tar.gz $target_LogPath > $OTHER_TTY 2>&1
        cd - > $OTHER_TTY 2>&1
        #upload
        $INIT_UPLOAD_SCRIPT "${base_Log_Path}/${target_LogPath}.tar.gz" "$LOG_SERVER_URL" $LOG_FILE
        if [ $? -ne 0 ];then
            g_LOG_Warn "Upload log failed."
        fi
    fi

    #copy LOG_FILE to disk
#####modified for mkinitrd on /dev/ram0#########
    if [ "$INSTALL_TARGET" == "$INSTALL_TARGET_UDISK" ];then
        local mount_info="`cat ${LOCAL_DISK_PATH}/etc/fstab_bak | grep -w "/tmp/udisk/tmp"`"
        local mount_part="`echo ${mount_info} | awk '{print $1}'`"
        local mount_point="`echo ${mount_info} | awk '{print $2}'`"
        local mount_fstype="`echo ${mount_info} | awk '{print $3}'`"

        g_LOG_Debug " >>$mount_info<< mkdir -p ${LOCAL_DISK_PATH}${mount_point}"
        mkdir -p ${LOCAL_DISK_PATH}${mount_point}

        mount -t "${mount_fstype}" "${mount_part}" "${LOCAL_DISK_PATH}${mount_point}" >${OTHER_TTY} 2>&1
        cp -ap $LOG_FILE ${LOCAL_DISK_PATH}${mount_point}/var/log/miniOS  > $OTHER_TTY 2>&1
        g_LOG_Info "cp $LOG_FILE ${LOCAL_DISK_PATH}${mount_point}/var/log/miniOS"
        if [ -f /var/log/miniOS_dmesg ];then
            cp -ap /var/log/miniOS_dmesg ${LOCAL_DISK_PATH}${mount_point}/var/log/miniOS/dmesg > $OTHER_TTY 2>&1
            g_LOG_Info "cp /var/log/miniOS_dmesg ${LOCAL_DISK_PATH}${mount_point}/var/log/miniOS/dmesg "
        fi
    else
        if [ ! -d "$local_OS_LogPath" ];then
            mkdir -p $local_OS_LogPath > $OTHER_TTY 2>&1
        fi
        cp -ap $LOG_FILE $local_OS_LogPath  > $OTHER_TTY 2>&1
        if [ -f /var/log/miniOS_dmesg ];then
            cp -ap /var/log/miniOS_dmesg $local_OS_LogPath/dmesg > $OTHER_TTY 2>&1
        fi
    fi
#####modified for mkinitrd on /dev/ram0#########
    return 0
}

#########################################################
#    Description: capture signal(Ctrl+C, kill -9 ...)
#    Return:      0-success, 1-failed
#########################################################
function INIT_Signal_Catcher()
{
    echo ""
}

#########################################################
#    Description: Clean install temp file
#    Return:      0-success, 1-failed
#########################################################
function INIT_Clean()
{
    #delete root password
    sed -i '/PASSWORD/d' $SYSCONFIG_CONF > $OTHER_TTY 2>&1
}

#########################################################
#    Description: format /etc/fstab
#    Return:      0-success, 1-failed
#########################################################
function INIT_Format_Fstab()
{
    local fstab=$1

    if [ -f $fstab ];then
        cat $fstab | sort -bk 2 > ${fstab}_tmp
        cp ${fstab}_tmp $fstab
    fi

    return 0
}

#########################################################
#    Description: wait for reboot
#    Input:
#        $1: wait times
#    Return:      0-success, 1-failed
#########################################################
function INIT_Wait_Reboot()
{
    local count=$1
    while [ $count -gt 0 ]
    do
        echo -e " $count \c "
        ((count--))
        sleep 1
    done
    echo ""
}

#########################################################
#    Description: set user  password 
#    Input:
#    Return:      0-success, 1-failed
#########################################################
function SET_user_password()
{

        PASSWD=`shm_ipc 1 "8259" 2>$OTHER_TTY`
        if [ $? -ne 0 ];then
            g_LOG_Error "set root passwd to target system error"
            return 1
        fi
        tempstr=`echo $PASSWD | awk '{print $NF}'`
        export USR_PASSWORD=${tempstr}

        mount  --bind /dev  ${LOCAL_DISK_PATH}/dev
        cp /usr/Euler/project/init/changepasswd.sh   ${LOCAL_DISK_PATH}/home/changepasswd.sh
        chroot ${LOCAL_DISK_PATH} /bin/expect  "/home/changepasswd.sh"   "${USR_PASSWORD}"

        rm -rf ${LOCAL_DISK_PATH}/home/changepasswd.sh
        umount  ${LOCAL_DISK_PATH}/dev
        export USR_PASSWORD=""
}

#########################################################
#########################################################
#    Description: copy config file(UVPOSsetup.conf) to OS
#    Return:      0-success, 1-failed
#########################################################
function INIT_CpCfgToOS()
{
    #if user dose not config net,use PXE's net card
    if [ -z "`ls $LOCAL_TEMPCFG_PATH | grep 'ifcfg-eth*'`" ];then
        cat <<EOF >ifcfg-$NET_DEVICE
BOOTPROTO="dhcp"
DEVICE="$NET_DEVICE"
IPADDR=""
NETMASK=""
GATEWAY=""
ONBOOT="no"
USERCTL="no"
EOF
    fi

    #Syncretic config file
    g_LOG_Info "Starting syncretic config file..."
    g_INIT_SyncreticCfg $TOTAL_CONF
    if [ $? -ne 0 ];then
        g_LOG_Warn "Syncretic config file failed"
    fi

    #delete root password
    sed -i '/PASSWORD=/d' $TOTAL_CONF > $OTHER_TTY 2>&1
    #delete hostname
    sed -i '/HOSTNAME=/d' $TOTAL_CONF > $OTHER_TTY 2>&1
    sed -i '/INSTALL_MEDIA=/d' $TOTAL_CONF > $OTHER_TTY 2>&1
    #cp config file to OS
    cp $TOTAL_CONF $LOCAL_TEMPCFG_PATH/new.part ${LOCAL_DISK_PATH}/etc/ > $OTHER_TTY 2>&1

    return $?
}

########################################################
 #    Description: the entry of install
#    Return:      0-success, 1-failed
#########################################################
function INIT_Setup_Main()
{
    #defined local variable
    local partition_detail=$LOCAL_TEMPCFG_PATH/partition.detail
    local isopackage_sdf=$LOCAL_TEMPCFG_PATH/isopackage.sdf
    local stage_file=$LOCAL_TEMPCFG_PATH/stage
    local install_des=$LOCAL_TEMPCFG_PATH/install_des
    local sysconfig_conf=`basename $SYSCONFIG_CONF`

    if [ -f "$OS_RELEASE_FILE_REDHAT" ]; then
        SI_CMDTYPE="rh-cmd"
    else
        SI_CMDTYPE="sl-cmd"
    fi
    g_LOG_Debug "SI_CMDTYPE is $SI_CMDTYPE"

    $INIT_MODULES
    g_LOG_Notice "Initializing modules success."

    #Initial Environment
    g_LOG_Notice "Initializing enviroment..."
    INIT_InsEnv_Initial
    if [ $? -ne 0 ];then
        g_LOG_Error "Initial enviroment failed."
        cat $LOG_FILE | grep -w "ERROR" | awk -F ': ' '{print $2}' > logtmp
	num=0
	while read line
	do
	    let num=num+1
	    if [ $num -lt 3 ];then
	        echo -e "\e[1;31m"${line}"\e[0m"
	    else
	        echo ${line}
	    fi
	done < logtmp
	rm logtmp
        return 1
    fi

    INIT_Execute_Hook $BEFORE_INSTALL_HOOK $BEFORE_INSTALL_HOOK
    if [ $? -ne 0 ];then
        g_LOG_Error "Execute before_install_hook failed."
        return 1
    fi

    #parse install_target,"hdisk" or "udisk"; parse install_disk
        INIT_check_install_target_and_disk
        if [ $? -ne 0 ];then
            g_LOG_Error "Init install_target or install_disk failed."
            return 1
    fi

    if [ -f /tmp/.reconf ]; then
        servercfg=`cat /tmp/.reconf`
        if [ -z ${servercfg} ]; then
            g_LOG_Warn "reconf url is empty"
        else
            CFG_SERVER_URL=${servercfg}
            INIT_Load_InsDir
            if [ $? -ne 0 ];then
                g_LOG_Error "Load install directory error."
                INIT_Print_Global
                return 1
            fi
        fi
    fi

    INIT_InsEnv_Initial2
    if [ $? -ne 0 ];then
        g_LOG_Error "Initial enviroment phase2 failed."
        cat $LOG_FILE | grep -w "ERROR" | awk -F ': ' '{print $2}' > logtmp
	num=0
	while read line
	do
	    let num=num+1
	    if [ $num -lt 3 ];then
	        echo -e "\e[1;31m"${line}"\e[0m"
	    else
	        echo ${line}
	    fi
	done < logtmp
	rm logtmp
        return 1
    fi
    g_LOG_Notice "Initializing enviroment success."

    #check INSTALL_MEDIA , if is CD, call UI
    if [ `echo $INSTALL_MEDIA | grep -i "CD"` ];then
        g_LOG_Notice "Searching driver disk..."
        HWM_GetUVPDrivers
        if [ $? -ne 0 ];then
            g_LOG_Error "Failed to get information of driver disks"
            return 1
        fi
        g_LOG_Notice "Search finished..."

        g_LOG_Notice "Calling UI to config..."
        #call UI
        python $INIT_UI_SCRIPT $LOCAL_TEMPCFG_PATH $sysconfig_conf
        if [ $? -ne 0 ];then
            g_LOG_Error "Config host failed..."
            return 1
        fi
        g_LOG_Notice "Config host finished..."

        #change global var "INSTALL_TARGET" according UI choice disk
        if [ -z "`cat $INSTALL_TARGET_TMP_FILE`" ];then
            g_LOG_Error "Get install target from ui failed..."
            return 1
        fi
        INSTALL_TARGET=`cat $INSTALL_TARGET_TMP_FILE | awk -F "=" '{print $2}'`

        #change global var "INSTALL_DISK" according UI choice disk
        if [ -z "`cat $INSTALL_DISK_TMP_FILE`" ];then
                g_LOG_Error "Get install disk from ui failed..."
                return 1
        fi
        INSTALL_DISK=`cat $INSTALL_DISK_TMP_FILE | awk -F "=" '{print $2}'`
		
		#change global var "SOFT_RAID" according UI choice softraid
        if [ -f /tmp/cfg/softraid-on ];then
                SOFT_RAID="on"
        fi
    fi

    INIT_Parse_Sysconfig
    if [ $? -ne 0 ];then
        return 1
    fi

    clear
    #stage change to FDISK_FORMAT
    g_MT_StageChangeTo "DISK_FORMAT"
    #Call UI to display install schedule at background
    python $INIT_UIPROGRESS_SCRIPT $LOCAL_TEMPCFG_PATH $LOG_FILE &
    #wirte ui pid 2 /tmp/uipid
    uipid=$!
    echo "${uipid}" >/tmp/uipid
    #sleep 2

    g_LOG_Notice "Creating and formatting partitions..."
    #Create and format partition
	if [ $SOFT_RAID = "off" ];then
		g_DM_CreateAndFormatPartition $FSTAB_FILE
		if [ $? -ne 0 ];then
			g_LOG_Error "Create and Format partitions failed."
			return 1
		fi
	else
		sh /usr/Euler/project/disk-partition/format-disk.sh -i -t lemon -c $LOCAL_TEMPCFG_PATH/softraid.conf > /dev/null 2>&1
		if [ $? -ne 0 ];then
			g_LOG_Error "Create and Format softraid partitions failed."
			return 1
		fi
		cat /usr/Euler/project/disk-partition/format-cmd/tmp/fstab.tmp | sort -b -k 2,2 > $FSTAB_FILE
	fi
    g_LOG_Notice "Creating and formatting partitions successed"

    #mount partitions
    g_LOG_Notice "Mounting partitions..."
    g_DM_MountPartitionToTarget $LOCAL_DISK_PATH $FSTAB_FILE
    if [ $? -ne 0 ];then
        g_LOG_Error "Mount partitions failed."
        return 1
    fi
    g_LOG_Notice "Mount partitions success."

    g_LOG_Notice "Loading OS tar package..."
    sleep 1
    #stage change to OS_INSTALL
    g_MT_StageChangeTo "COPY_PKG"
    #copy OS tar packge
    g_Load_Os > $OTHER_TTY 2>&1
    if [ $? -ne 0 ];then
        g_LOG_Error "Load OS tar package failed."
        return 1
    fi
    g_LOG_Notice "Load OS tar package success."

    #setup OS to disk
    g_LOG_Notice "Starting setup OS..."
    sleep 1
    g_MT_StageChangeTo "OS_INSTALL"
    local isopackage_md5=$LOCAL_SOURCE_PATH/isopackage.md5
    $INIT_SETUPOS_SCRIPT $isopackage_sdf $INSTALL_MODE $isopackage_md5
    if [ $? -ne 0 ];then
        g_LOG_Error "Setup OS failed."
        return 1
    fi

    if [ `echo $INSTALL_MEDIA | grep -i "CD"` ];then
       SET_user_password
       if [ $? -ne 0 ];then
          g_LOG_Error "set root passwd to target system error"
          return 1
       fi
    fi
    g_LOG_Notice "Setup OS success."

    #Execute before_mkfirstboot_hook
    INIT_Execute_Hook $BEFORE_MKFIRSTBOOT_HOOK $LOCAL_DISK_PATH
    if [ $? -ne 0 ];then
        g_LOG_Error "Execute before_mkfirstboot_hook failed."
        return 1
    else
        cp $BEFORE_MKFIRSTBOOT_HOOK/ifcfg-* $LOCAL_TEMPCFG_PATH > $OTHER_TTY 2>&1
    fi

    #Generate firstboot script
    g_LOG_Notice "Generating firstboot script..."
    $INIT_MKFIRSTBOOT_SCRIPT
    if [ $? -ne 0 ];then
        g_LOG_Error "Generate firstboot script failed."
        return 1
    fi
    g_LOG_Notice "Generate firstboot script success."

    #Syncretic config file and cp to OS
    g_LOG_Notice "Syncreticing config file and copy to OS..."
    INIT_CpCfgToOS
    if [ $? -ne 0 ];then
        g_LOG_Warn "Copy config file to OS failed."
    fi
    g_LOG_Notice "Syncretice config file and copy to OS success."

    #move invoke of finshed usb install scripts from mkfirstboot.sh to here
    $INIT_FINSH_USB_INSTALL
    if [ $? -ne 0 ];then
          g_LOG_Error "finshed USB install Error"
          return 1
    fi
    g_LOG_Notice "Install OS success."

    return 0
}

#capture signal
trap "INIT_Signal_Catcher" INT TERM QUIT

#start setup OS
INIT_Setup_Main
ret=$?

if [ $ret -ne 0 ];then
    g_LOG_Error "Install OS failed."
    INIT_Execute_Hook $AFTER_INSFAIL_HOOK $AFTER_INSFAIL_HOOK
else
    #Execute after_inssucc_hook
    INIT_Execute_Hook $AFTER_INSSUCC_HOOK $AFTER_INSSUCC_HOOK
    ret=$?
fi

#get pid of ui
if [ -f /tmp/uipid ];then
    processPid="`cat /tmp/uipid`"
    rm /tmp/uipid
fi
#change stage
if [ $ret -eq 0 ];then
    #stage change to FINISH
    g_MT_StageChangeTo "FINISH" >/dev/null 2>&1
else
    #handle exception
    g_MT_StageChangeTo "FAILED" >/dev/null 2>&1
    #waiting for ui proces finished
    if [ -n "$processPid" -a -d /proc/$processPid ];then
        wait $processPid
    fi
    #INIT_Clean
    echo "Install OS failed,Please login from TTY2 (Press ALT-F2)."
    exit 1
fi
#waiting for ui process finished
if [ -n "$processPid"  -a -d /proc/$processPid ];then
    wait $processPid
fi

INIT_Execute_Hook_No_Redict_Output $BEFORE_REBOOT_HOOK $BEFORE_REBOOT_HOOK
if [ $? -ne 0 ]; then
    g_LOG_Error "Execute $BEFORE_REBOOT_HOOK failed."
    exit 1
fi

#upload Log
dmesg > /var/log/miniOS_dmesg
chmod 640 /var/log/miniOS_dmesg
g_LOG_Notice "Uploading log file."
INIT_Upload_LOG >/dev/null 2>&1
rm -rf ${LOCAL_DISK_PATH}/var/log/YaST2/* >/dev/null 2>&1

#umount disk
mp=$(mount | grep "${LOCAL_DISK_PATH}" | awk -F " " '{print $3}')
for i in ${mp}
do
	if [ "$i" != "${LOCAL_DISK_PATH}" ];then
		umount $i
		if [ $? -ne 0 ];then
			umount -l $i
		fi
	fi
	if [ "$i" = "${LOCAL_DISK_PATH}" ];then
		end_mp="${LOCAL_DISK_PATH}"
	fi
done
umount $end_mp
if [ $? -ne 0 ];then
	umount -l $end_mp
fi

echo "The System will be reboot after 5 seconds."
INIT_Wait_Reboot 5


reboot
