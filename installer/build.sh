#!/bin/sh
app=ekylibre
p=`readlink -f $0`
current_dir=`dirname $p`
rails_root=`dirname ${current_dir}`

line=`cat ${rails_root}/VERSION`
name=`echo ${line} | cut -d',' -f1`
version=`echo ${line} | cut -d',' -f2`
#latest=${version}-${name}
latest=${version}
# release=${app}-${latest}
release=${app}-${version}

#datadir=$HOME/Public/${app}/${version}
datadir=${current_dir}/releases/${version}
resdir=${current_dir}/resources
log_base=${current_dir}/build-${release}
sources=1
debian=1
win32=1
checksums=1

help_message() {
    name=`basename $0` 
    echo "$name create installers for ${app}"
    echo ""
    echo "Usage:"
    echo "  $name [OPTIONS]"
    echo ""
    echo "Options"
    echo "  -c                     Skip checksums computation"
    echo "  -d DATADIR             where the binary are stored"
    echo "                         Default: ${datadir}" 
    echo "  -h                     display help message"
    echo "  -r RESDIR              where the resources files can be found"
    echo "                         Default: ${resdir}"
    echo "  -s                     Skip sources packaging"
    echo "  -l LOG_FILE            Log file location"
    echo "                         Default: ${log}" 
    echo "  -u                     Skip Debian packaging"
    echo "  -w                     Skip Win32 packaging (with NSIS)"
    echo ""
    echo "Report bugs at <dev@ekylibre.org>"
}

# Initialize
while getopts cd:hl:r:suw o
do 
    case "$o" in
        c)   checksums=0;;
        d)   datadir="$OPTARG";;
        h)   help_message
            exit 0;;
        l)   log_base="$OPTARG";;
        s)   sources=0;;
        r)   resdir="$OPTARG";;
        u)   debian=0;;
        w)   win32=0;;
        [?]) help_message
            exit 1;;
    esac
done
shift `expr $OPTIND - 1`

echo "Output directory:    ${datadir}"
echo "Resources directory: ${resdir}"

rm -fr ${datadir}
mkdir -p ${datadir}

log=${log_base}.log

mkdir -p `dirname $log`
echo "== Build =================================================================================" > $log

for build in source debian win32
do
    script=${current_dir}/${build}/build
    if [ -e ${script} ]; then
	echo " * Building ${build} packages..."
	echo "" >> $log
	echo "------------------------------------------------------------------------------------------" >> $log
	echo "-- Build ${build} packages" >> $log
	echo "------------------------------------------------------------------------------------------" >> $log
	start=`date +%s.%N`

	cd ${current_dir}/${build}

	# Link project tree
	echo " * Generates project tree..." >> $log
	rm -fr ${app}
	mkdir ${app}
	ln -s ${rails_root}/* $app/
	for dir in config-* installer log private tmp ; do
	    rm -f $app/$dir
	done
	for dir in log private tmp ; do
	    mkdir $app/$dir
	done

	# Build packages
	echo " * Packages..." >> $log
	blog="${log_base}.${build}.log"
	echo "------------------------------------------------------------------------------------------" > $blog
	echo "-- Build ${build} packages" >> $blog
	echo "------------------------------------------------------------------------------------------" >> $blog
	./build ${app} ${version} ${blog} ${resdir}/win32
	echo " * See ${blog} for details." >> $log

	# Move packages
	echo " * Finishes..." >> $log
	packages="`pwd`/packages"
	if [ -e ${packages} ]; then
	    rm -fr ${datadir}/${build}
	    mv ${packages} ${datadir}/${build}
	else
	    echo "ERROR: Unable to find the directory named '${packages}' which is theoretically produced by ${script}"
	fi
	# rm -fr ${app}

	finish=`date +%s.%N`
	total=`echo "${finish}-${start}" | bc`
	echo "------------------------------------------------------------------------------------------" >> $log
	echo "-- ${build} packages where built in ${total} seconds" >> $log
    else
	echo " * Warning: Can not build ${build} packages. No build script found."
	echo "" >> $log
	echo "------------------------------------------------------------------------------------------" >> $log
	echo "-- Can not build ${build} packages: No build script found" >> $log
	echo "------------------------------------------------------------------------------------------" >> $log
    fi
done

# # Sources
# if [ $sources = 1 ]; then
#     echo " * Compressing sources..."
#     echo "-- Source Building -------------------------------------------------------------------------------" >> $log
#     mkdir -p release/source
#     source=${release}-source
#     echo " * Zip source" >> $log
#     zip -r    ${source}.zip ${app}   -x "*.svn*" >> $log
#     echo " * Gzip source" >> $log
#     tar cfvhz ${source}.tar.gz  --exclude=.svn ${app} >> $log
#     echo " * Bzip source" >> $log
#     tar cfvhj ${source}.tar.bz2 --exclude=.svn ${app} >> $log
#     mv ${source}.* release/source/
# fi


# # Debian
# if [ $debian = 0 ]; then
#     echo " * Debian compilation..."
    
#     # rake -f ${current_dir}/debian/Rakefile build APP=${app} VERSION=${version}
#     cp -r ${current_dir}/debian/
#     mkdir -p debian/${app}-common/
#     cp -r ${app}
#     # mkdir release/debian
# fi

# # Win32
# if [ $win32 = 1 ]; then
#     echo " * Win32 compilation..."
#     resources=${tmpdir}/win32
#     rm -fr ${resources}
#     mkdir -p ${resources}/apps
#     ln -s ${tmpdir}/${app} ${resources}/apps/${app}
#     ln -s ${resdir}/* ${resources}/
#     echo "-- Win32 packaging with NSIS --------------------------------------------------------------------" >> $log
#     date >> $log
#     makensis -DRELEASE=${release} -DVERSION=${version} -DRESOURCES=${resources} -DIMAGES=${current_dir}/windows/images ${current_dir}/windows/installer.nsi >> $log
#     date >> $log
#     mkdir -p release/win32
#     mv ${current_dir}/windows/${release}.exe release/win32
# fi

# # Mac OS
# # mkdir release/macos

cd ${datadir}

# Checksums
if [ $checksums = 1 ]; then
    echo " * Checksum computation..."
    sha1sum ./*/* > SHA1SUMS
    md5sum ./*/* > MD5SUMS
fi

# Deploiement
echo " * Deploying..."
if [ `whoami` = root ]; then
    chown www-data.www-data -R ${datadir}
fi


