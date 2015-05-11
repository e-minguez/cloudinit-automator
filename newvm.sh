#!/bin/sh

OS=$(echo $1 | tr '[:lower:]' '[:upper:]')
VERSION=$2
NAME=$3
IP=$4

die()
{
  echo $1
  exit $2
}

[ -z $OS ] && die "OS not found" 2
[ -z $VERSION ] && die "Version not found" 2
[ -z $NAME ] && die "Name not found" 2

TEMPLATE=${OS}${VERSION}TEMPLATE

VMSTORAGE="/storage/vms"
DOMAIN="rh.lan"
CLOUDINITDIR="/storage/software/cloudinit"
TEMPLATESDIR="${CLOUDINITDIR}/templates"

METADATATEMPLATE="${TEMPLATESDIR}/meta-data-template"
USERDATATEMPLATESTATIC="${TEMPLATES}/user-data-template-static-${VERSION}"
USERDATATEMPLATEDHCP="${TEMPLATES}/user-data-template-dhcp-${VERSION}"

METADATA="${CLOUDINITDIR}/meta-data"
USERDATA="${CLOUDINITDIR}/user-data"

CLOUDINITISO="/storage/isos/cloudinit.iso"

sudo /usr/bin/virt-clone -o ${TEMPLATE} -n ${NAME} -f ${VMSTORAGE}/${NAME}.qcow2

sed -e "s/INSTANCEID/${NAME}/g" -e "s/HOSTNAME/${NAME}.${DOMAIN}/g" ${METADATATEMPLATE} > ${METADATA}

if [ -z ${IP} ]
then
  cp ${USERDATATEMPLATEDHCP} ${USERDATA}
else
  sed -e "s/INSTANCEIP/${IP}/g" ${USERDATATEMPLATESTATIC} > ${USERDATA}
fi

rm -f ${CLOUDINITISO}
pushd ${CLOUDINITDIR}
/usr/bin/genisoimage -output ${CLOUDINITISO} -volid cidata -joliet -rock user-data meta-data
popd

sudo chown $USER ${VMSTORAGE}/${NAME}.qcow2

sudo /usr/bin/virsh start ${NAME}

exit 0
