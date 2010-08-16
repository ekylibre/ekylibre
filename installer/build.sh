#!/bin/sh
app=ekylibre
p=`readlink -f $0`
current_dir=`dirname $p`
rails_root=${current_dir}/..

line=`cat ${rails_root}/VERSION`
name=`echo ${line} | cut -d',' -f1`
version=`echo ${line} | cut -d',' -f2`
#latest=${version}-${name}
latest=${version}
# release=${app}-${latest}
release=${app}-${version}

datadir=$HOME/Public/${app}
tmpdir=/tmp/${release}
resdir=${current_dir}/windows/resources
sources=1
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
    echo "  -r RESDIR              where the resources files can be found (for Win32 installer)"
    echo "                         Default: ${resdir}"
    echo "  -s                     Skip sources packaging"
    echo "  -t TMPDIR              where the files can be compiled"
    echo "                         Default: ${tmpdir}" 
    echo "  -w                     Skip Win32 packaging (with NSIS)"
    echo ""
    echo "Report bugs at <dev@ekylibre.org>"
}

# Initialize
while getopts cd:hr:st:w o
do 
    case "$o" in
        c)   checksums=0;;
        d)   datadir="$OPTARG";;
        h)   help_message
            exit 0;;
        s)   sources=0;;
        r)   resdir="$OPTARG";;
        t)   tmpdir="$OPTARG";;
        w)   win32=0;;
        [?]) help_message
            exit 1;;
    esac
done
shift `expr $OPTIND - 1`

echo "Output directory:    ${datadir}"
echo "Build directory:     ${tmpdir}"
echo "Resources directory: ${resdir}"

mkdir -p ${tmpdir}
mkdir -p ${datadir}/releases

cd ${tmpdir}

# Récupération des dernières sources
#echo " * Exporting data..."
rm -fr ${app}
mkdir ${app}
for file in app config config.ru db Gemfile lib LICENSE public Rakefile script vendor VERSION ; do
    ln -s ${rails_root}/$file $app/
done
for dir in log private tmp ; do
    mkdir $app/$dir
done
# ln -s ${rails_root}/* $app/
# rm $app/installer

# Création du répertoire de base
rm -fr release
mkdir -p release
log=${tmpdir}/log
mkdir -p $log

# Sources
if [ $sources = 1 ]; then
    echo " * Compressing sources..."
    mkdir -p release/source
    source=${release}-source
    zip -r    ${source}.zip ${app}   -x "*.svn*" > $log/zip.log
    tar cfvhz ${source}.tar.gz  --exclude=.svn ${app} > $log/tgz.log
    tar cfvhj ${source}.tar.bz2 --exclude=.svn ${app} > $log/bz2.log
    mv ${source}.* release/source/
fi

# Win32
if [ $win32 = 1 ]; then
    echo " * Win32 compilation..."
    resources=${tmpdir}/win32
    rm -fr ${resources}
    mkdir -p ${resources}/apps
    ln -s ${tmpdir}/${app} ${resources}/apps/${app}
    ln -s ${resdir}/* ${resources}/
    echo "-- Win32 packaging with NSIS --------------------------------------------------------------------" > $log/win32.log
    date >> $log/win32.log
    makensis -DRELEASE=${release} -DVERSION=${version} -DRESOURCES=${resources} -DIMAGES=${current_dir}/windows/images ${current_dir}/windows/installer.nsi >> $log/win32.log
    date >> $log/win32.log
    mkdir -p release/win32
    mv ${current_dir}/windows/${release}.exe release/win32
fi

# Debian
# mkdir release/debian

# Mac OS
# mkdir release/macos

# Checksums
if [ $checksums = 1 ]; then
    echo " * Checksum computation..."
    cd release
    sha1sum ./*/* > SHA1SUMS
    md5sum ./*/* > MD5SUMS
fi

# Deploiement
echo " * Deploying..."
cd ${datadir}/releases
rm -fr ${latest}
mv ${tmpdir}/release ${latest}
rm -f latest
ln -s ${latest} latest
# rm -fr ${tmpdir}
if [ `whoami` = root ]; then
    chown www-data.www-data -R ${datadir}
fi


