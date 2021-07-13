#! /bin/sh

source /jffs/softcenter/scripts/base.sh
eval $(dbus export ss)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=$(nvram get productid)

mkdir -p /jffs/softcenter/ss
mkdir -p /tmp/upload

firmware_version=`dbus get softcenter_firmware_version`
#api1.5
firmware_check=5.1.2

firmware_comp=`/jffs/softcenter/bin/versioncmp $firmware_version $firmware_check`
if [ "$firmware_comp" == "1" ];then
	echo_date 1.5代api最低固件版本为5.1.2,固件版本过低，无法安装
	exit 1
fi

if [ "${MODEL:0:3}" == "GT-" ] || [ "$(nvram get swrt_rog)" == "1" ];then
	ROG=1
elif [ "${MODEL:0:3}" == "TUF" ] || [ "$(nvram get swrt_tuf)" == "1" ];then
	TUF=1
fi

# 先关闭ss
if [ "$ss_basic_enable" == "1" ];then
	echo_date 先关闭helloworld插件，保证文件更新成功!
	sh /jffs/softcenter/ss/ssconfig.sh stop
fi

if [ -n "$(ls /jffs/softcenter/ss/postscripts/P*.sh 2>/dev/null)" ];then
	echo_date 备份触发脚本!
	find /jffs/softcenter/ss/postscripts -name "P*.sh" | xargs -i mv {} -f /tmp/ss_backup
fi


#升级前先删除无关文件
echo_date 清理旧文件
rm -rf /jffs/softcenter/ss/*
rm -rf /jffs/softcenter/scripts/ss_*
rm -rf /jffs/softcenter/webs/Module_helloworld*
rm -rf /jffs/softcenter/bin/ss-redir
rm -rf /jffs/softcenter/bin/ss-local
rm -rf /jffs/softcenter/bin/ssr-redir
rm -rf /jffs/softcenter/bin/ssr-local
rm -rf /jffs/softcenter/bin/obfs-local
rm -rf /jffs/softcenter/bin/dns2socks
rm -rf /jffs/softcenter/bin/client_linux
rm -rf /jffs/softcenter/bin/chinadns-ng
rm -rf /jffs/softcenter/bin/v2ray-plugin
rm -rf /jffs/softcenter/bin/trojan
rm -rf /jffs/softcenter/bin/xray
rm -rf /jffs/softcenter/bin/httping
rm -rf /jffs/softcenter/res/icon-helloworld.png
rm -rf /jffs/softcenter/res/ss-menu.js
rm -rf /jffs/softcenter/res/tablednd.js
rm -rf /jffs/softcenter/res/helloworld.css
find /jffs/softcenter/init.d/ -name "*helloworld.sh" | xargs rm -rf
find /jffs/softcenter/init.d/ -name "*socks5.sh" | xargs rm -rf

echo_date 开始复制文件！
cd /tmp

echo_date 复制相关二进制文件！此步时间可能较长！
cp -rf /tmp/helloworld/bin/* /jffs/softcenter/bin/

echo_date 复制相关的脚本文件！
cp -rf /tmp/helloworld/ss /jffs/softcenter/
cp -rf /tmp/helloworld/scripts/* /jffs/softcenter/scripts/
cp -rf /tmp/helloworld/install.sh /jffs/softcenter/scripts/ss_install.sh
cp -rf /tmp/helloworld/uninstall.sh /jffs/softcenter/scripts/uninstall_helloworld.sh

echo_date 复制相关的网页文件！
cp -rf /tmp/helloworld/webs/* /jffs/softcenter/webs/
cp -rf /tmp/helloworld/res/* /jffs/softcenter/res/
if [ "$ROG" == "1" ];then
	echo_date "为插件安装ROG UI..."
	cp -rf /tmp/helloworld/rog/res/helloworld.css /jffs/softcenter/res/
elif [ "$TUF" == "1" ];then
	echo_date "为插件安装TUF UI..."
	sed -i 's/3e030d/3e2902/g;s/91071f/92650F/g;s/680516/D0982C/g;s/cf0a2c/c58813/g;s/700618/74500b/g;s/530412/92650F/g' /tmp/helloworld/rog/res/helloworld.css >/dev/null 2>&1
	cp -rf /tmp/helloworld/rog/res/helloworld.css /jffs/softcenter/res/
else
	echo_date "为插件安装ASUSWRT UI..."
fi
echo_date 为新安装文件赋予执行权限...
chmod 755 /jffs/softcenter/ss/rules/*
chmod 755 /jffs/softcenter/ss/*
chmod 755 /jffs/softcenter/scripts/ss*
chmod 755 /jffs/softcenter/bin/*

if [ -n "$(ls /tmp/ss_backup/P*.sh 2>/dev/null)" ];then
	echo_date 恢复触发脚本!
	mkdir -p /jffs/softcenter/ss/postscripts
	find /tmp/ss_backup -name "P*.sh" | xargs -i mv {} -f /jffs/softcenter/ss/postscripts
fi

echo_date 创建一些二进制文件的软链接！
[ ! -L "/jffs/softcenter/init.d/S99helloworld.sh" ] && ln -sf /jffs/softcenter/ss/ssconfig.sh /jffs/softcenter/init.d/S99helloworld.sh
[ ! -L "/jffs/softcenter/init.d/N99helloworld.sh" ] && ln -sf /jffs/softcenter/ss/ssconfig.sh /jffs/softcenter/init.d/N99helloworld.sh
[ ! -L "/jffs/softcenter/init.d/S99socks5.sh" ] && ln -sf /jffs/softcenter/scripts/ss_socks5.sh /jffs/softcenter/init.d/S99socks5.sh

# 设置一些默认值
echo_date 设置一些默认值
[ -z "$ss_dns_china" ] && dbus set ss_dns_china=11
[ -z "$ss_dns_foreign" ] && dbus set ss_dns_foreign=1
[ -z "$ss_acl_default_mode" ] && dbus set ss_acl_default_mode=1
[ -z "$ss_acl_default_port" ] && dbus set ss_acl_default_port=all
[ -z "$ss_basic_interval" ] && dbus set ss_basic_interval=2

# 离线安装时设置软件中心内储存的版本号和连接
CUR_VERSION=$(cat /jffs/softcenter/ss/version)
dbus set ss_basic_version_local="$CUR_VERSION"
dbus set softcenter_module_helloworld_install="1"
dbus set softcenter_module_helloworld_version="$CUR_VERSION"
dbus set softcenter_module_helloworld_title="helloworld"
dbus set softcenter_module_helloworld_description="helloworld"

# 设置v2ray 版本号
dbus set ss_basic_v2ray_version="v4.32.1"

echo_date 一点点清理工作...
rm -rf /tmp/helloworld* >/dev/null 2>&1

echo_date helloworld插件安装成功！

if [ "$ss_basic_enable" == "1" ];then
	echo_date 重启helloworld插件！
	sh /jffs/softcenter/ss/ssconfig.sh restart
fi

echo_date 更新完毕，请等待网页自动刷新！
exit 0

