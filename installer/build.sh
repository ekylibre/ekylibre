#!/bin/sh
app=ekylibre
p=`readlink -f $0`
current_dir=`dirname $p`

line=`cat ${current_dir}/../VERSION`
name=`echo ${line} | cut -d',' -f1`
version=`echo ${line} | cut -d',' -f2`
latest=${version}-${name}
release=${app}-${latest}

datadir=$HOME/Public/${app}
tmpdir=/tmp/${release}
resdir=${current_dir}/windows/resources

help_message() {
    name=`basename $0` 
    echo "$name create installers for ${app}"
    echo ""
    echo "Usage:"
    echo "  $name [OPTIONS]"
    echo ""
    echo "Options"
    echo "  -d DATADIR             where the binary are stored"
    echo "                         Default: ${datadir}" 
    echo "  -h                     display help message"
    echo "  -r RESDIR              where the resources files can be found (for Win32 installer)"
    echo "                         Default: ${resdir}" 
    echo "  -t TMPDIR              where the files can be compiled"
    echo "                         Default: ${tmpdir}" 
    echo ""
    echo "Report bugs at <dev@ekylibre.org>"
}

# Initialize
while getopts d:hr:t: o
do 
    case "$o" in
        d)   datadir="$OPTARG";;
        h)   help_message
            exit 0;;
        r)   resdir="$OPTARG";;
        t)   tmpdir="$OPTARG";;
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
ln -s ${current_dir}/../* $app/
rm $app/installer

# Création du répertoire de base
rm -fr release
mkdir -p release/source
log=${tmpdir}/log
mkdir -p $log

# Sources
echo " * Compressing sources..."
source=${release}-source
zip -r    ${source}.zip ${app}   -x "*.svn*" > $log/zip.log
tar cfvhz ${source}.tar.gz  --exclude=.svn ${app} > $log/tgz.log
tar cfvhj ${source}.tar.bz2 --exclude=.svn ${app} > $log/bz2.log
mv ${source}.* release/source/

# Win32
echo " * Win32 compilation..."
# Creation of ressource data
resources=${tmpdir}/win32
rm -fr ${resources}
mkdir -p ${resources}/apps
ln -s ${tmpdir}/${app} ${resources}/apps/${app}
ln -s ${resdir}/* ${resources}/
echo "-- Win32 --------------------------------------------------------------------" > $log/nsi.log
date >> $log/nsi.log
makensis -DRELEASE=${release} -DVERSION=${version} -DRESOURCES=${resources} ${current_dir}/windows/installer.nsi >> $log/nsi.log
date >> $log/nsi.log
mkdir -p release/win32
mv ${current_dir}/windows/${release}.exe release/win32

# Debian
# mkdir release/debian

# Mac OS
# mkdir release/macos

# ISO & Checksums
echo " * Checksum computation..."
cd release
sha1sum ./*/* > SHA1SUMS
md5sum ./*/* > MD5SUMS

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


