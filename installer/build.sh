#!/bin/sh
app=ekylibre
p=`readlink -f $0`
current_dir=`dirname $p`

datadir=${current_dir}/data/${app}
tmpdir=${current_dir}/tmp/${app}
branch=trunk
resdir=/home/tasks/resources/${app}
svn_root=https://www.ekylibre.org/svn

help_message() {
    name=`basename $0` 
    # echo "Usage: $name [-d dbname] [-r relative_root_url] [-c database.yml] [-t] APP SVN TARGET"
    echo "$name create installers for ${app}"
    echo ""
    echo "Usage:"
    echo "  $name [OPTIONS]"
    echo ""
    echo "Options"
    echo "  -b BRANCH              SVN branch of the repository to use" 
    echo "                         Default: ${branch}" 
    echo "  -d DATADIR             where the binary are stored"
    echo "                         Default: ${datadir}" 
    echo "  -h                     display help message"
    echo "  -r RESDIR              where the resources files can be found (for Win32 installer)"
    echo "                         Default: ${resdir}" 
    echo "  -s SVN                 SVN repository root"
    echo "                         Default: ${svn_root}" 
    echo "  -t TMPDIR              where the files can be compiled"
    echo "                         Default: ${tmpdir}" 
    echo ""
    echo "Report bugs at <dev@ekylibre.org>"
}

# Initialize
while getopts b:d:hr:s:t: o
do 
    case "$o" in
        b)   branch="$OPTARG";;
        d)   datadir="$OPTARG";;
        h)   help_message
            exit 0;;
        r)   resdir="$OPTARG";;
	s)   svn_root="$OPTARG";;
        t)   tmpdir="$OPTARG";;
        [?]) help_message
            exit 1;;
    esac
done
shift `expr $OPTIND - 1`

# if [ -z $datadir ]; then
#     datadir=${current_dir}/data/${app}
# fi
# if [ -z $tmpdir ]; then
#     tmpdir=${current_dir}/tmp/${app}
# fi
# if [ -z $branch ]; then
#     branch=trunk
# fi
# if [ -z $resdir ]; then
#     resdir=/home/tasks/resources/${app}
# fi

echo "Output directory:    ${datadir}"
echo "Build directory:     ${tmpdir}"
echo "Resources directory: ${resdir}"
echo "SVN Path:            ${svn_root}/${app}/${branch}"

mkdir -p ${tmpdir}
mkdir -p ${datadir}/releases

cd ${tmpdir}

# Récupération des dernières sources
echo " * Exporting data..."
rm -fr ${app}
svn export ${svn_root}/${app}/${branch} ${app} > svn.log
line=`cat ${app}/VERSION`
name=`echo ${line} | cut -d',' -f1`
version=`echo ${line} | cut -d',' -f2`
latest=${version}-${name}
release=${app}-${latest}

# Création du répertoire de base
rm -fr ${latest}
mkdir ${latest}

# Sources
echo " * Compressing sources..."
source=${release}-source
zip -r   ${source}.zip ${app} > zip.log
tar cvzf ${source}.tar.gz ${app} > tgz.log
tar cjvf ${source}.tar.bz2 ${app} > bz2.log
mkdir ${latest}/source
mv ${source}.* ${latest}/source/

# Win32
echo " * Win32 compilation..."
# Creation of ressource data
resources=${tmpdir}/${app}-win32
rm -fr ${resources}
mkdir -p ${resources}/apps
ln -s ${tmpdir}/${app} ${resources}/apps/${app}
ln -s ${resdir}/* ${resources}
echo "-- Win32 --------------------------------------------------------------------" > nsi.log
date >> nsi.log
makensis -DRELEASE=${release} -DVERSION=${version} -DRESOURCES=${resources} ${current_dir}/windows/installer.nsi >> nsi.log
date >> nsi.log
mkdir -p ${latest}/win32
mv ${current_dir}/windows/${release}.exe ${latest}/win32

# Linux
# mkdir ${latest}/linux

# Mac OS
# mkdir ${latest}/macos

# ISO & Checksums
echo " * Checksum computation..."
cd ${latest}
sha1sum ./*/* > SHA1SUMS
md5sum ./*/* > MD5SUMS

# Deploiement
echo " * Deploying..."
cd ${datadir}/releases
rm -fr ${latest}
mv ${tmpdir}/${latest} .
rm -f latest
ln -s ${latest} latest
# rm -fr ${tmpdir}
if [ `whoami` = root ]; then
    chown www-data.www-data -R ${datadir}
fi


