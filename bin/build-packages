#!/bin/sh
mstart=`date +%s.%N`
app=ekylibre
p=`readlink -f $0`
current_dir=`dirname $p`
rails_root=`dirname ${current_dir}`

line=`cat ${rails_root}/VERSION`
version=`echo ${line} | cut -d',' -f1`
# version=`echo ${line} | cut -d',' -f2`
release=${app}-${version}

datadir=${current_dir}/releases/${version}
resdir=${current_dir}/resources
log_base=${current_dir}/build-${release}
checksums=1

help_message() {
    name=`basename $0` 
    echo "$name create installers for ${app}"
    echo ""
    echo "Usage:"
    echo "  $name [OPTIONS] [PACKAGES]"
    echo ""
    echo "Parameters"
    echo "   PACKAGES              List of packages to build. All if no one selected"
    echo ""
    echo "Options"
    echo "  -c                     Skip checksums computation"
    echo "  -d DATADIR             where the binary are stored"
    echo "                         Default: ${datadir}" 
    echo "  -h                     display help message"
    echo "  -l LOG_FILE            Main log file location"
    echo "                         Default: ${log_base}" 
    echo "  -r RESDIR              where the resources files can be found"
    echo "                         Default: ${resdir}"
    echo ""
    echo "Report bugs at <dev@ekylibre.org>"
}

# Initialize
while getopts cd:hl:r: o
do 
    case "$o" in
        c)   checksums=0;;
        d)   datadir="$OPTARG";;
        h)   help_message
            exit 0;;
        l)   log_base="$OPTARG";;
        r)   resdir="$OPTARG";;
        [?]) help_message
            exit 1;;
    esac
done
shift `expr $OPTIND - 1`

# Don't build for win32 anymore
builds_ref="source debian"
builds=${builds_ref}
if [ ! -z "$*" ]; then
    builds=$*
fi

rm -fr ${datadir}
mkdir -p ${datadir}

log=${log_base}.log
mkdir -p `dirname $log`

echo "== Build =================================================================================" > $log
echo "Output directory:    ${datadir}" >> $log
echo "Resources directory: ${resdir}"  >> $log

for build in $builds
do
    script=${current_dir}/${build}/build
    if [ -e ${script} ]; then
	echo " * Building ${build} packages..."
	echo "" >> $log
	echo "Build ${build} packages:" >> $log
	start=`date +%s.%N`

	cd ${current_dir}/${build}

	# Link project tree
	echo " * Generates project tree..." >> $log
	rm -fr ${app}
	mkdir ${app}
	ln -s ${rails_root}/* $app/
	for dir in installer log private tmp ; do
	    rm -f $app/$dir
	done
	for dir in log private tmp ; do
	    mkdir $app/$dir
	done


	# Build packages
	echo " * Packages..." >> $log
	blog="${log_base}.${build}.log"
	# blog="./build.log"
	echo "------------------------------------------------------------------------------------------" > $blog
	echo "-- Build ${build} packages" >> $blog
	echo "------------------------------------------------------------------------------------------" >> $blog
	./build ${app} ${version} ${blog} ${resdir}/${build}
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
	rm -fr ${app}

	finish=`date +%s.%N`
	total=`echo "${finish}-${start}" | bc`
	echo "=> ${build} packages where built in ${total} seconds" >> $log
    else
	echo " * Warning: Can not build ${build} packages. No build script found."
	echo "" >> $log
	echo "Can not build ${build} packages: No build script found." >> $log
    fi
done

cd ${datadir}

# Checksums
if [ $checksums = 1 ]; then
    echo " * Checksum computation..."
    sha256sum ./*/* > SHA256SUMS
    sha1sum  ./*/* > SHA1SUMS
    md5sum  ./*/* > MD5SUMS
fi

# Deployment
echo " * Deploying..."
if [ `whoami` = root ]; then
    chown www-data.www-data -R ${datadir}
fi

finish=`date +%s.%N`
total=`echo "${finish}-${mstart}" | bc`
echo "" >> $log
echo "All packages where built in ${total} seconds" >> $log
