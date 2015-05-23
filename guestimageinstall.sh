#!/bin/sh

# guestimageinstall
# Script to create a new vm based on a qcow2 image using cloudinit to customize it
# version 0.01
# Maintainer: Javier Ramirez javilinux@gmail.com
# Based on Eduardo Minguez job
#
# Usage
# guestimageinstall $nameofvm ($qcow2image)
# 
# TODO:
# - Static IPs

# Arguments
NAME=$1
QCOWIMAGE=$2

# Variables with directories and templates
IMAGESDIR="/opt/qcow2/"

STORAGE="/var/lib/libvirt/images/"
DOMAIN="sombrerorojo.com"

METADATATEMPLATE="/opt/cloudinit/meta-data-template"
METADATA="/opt/cloudinit/meta-data"

USERDATA="/opt/cloudinit/user-data"

CLOUDINITISO="/opt/isos/cloudinit.iso"

# We check if we passed the qcow2 image as argument
# if not we select it from the appropiate dir 
if [ -z "$QCOWIMAGE" ]
  then
	select QCOWIMAGE in ${IMAGESDIR}*;
	do
	     break
	done
fi

# we choose the user data template based on the version of the qcow2 image (RHEL 6 or RHEL 7) 
VERSION=`echo ${QCOWIMAGE} | cut -d- -f2-4 | cut -d. -f1`
USERDATATEMPLATEDHCP="/opt/cloudinit/user-data-${VERSION}"

# we copy the user data choosen template 
sudo cp ${USERDATATEMPLATEDHCP} ${USERDATA}

# We change the instance and hostname in the meta data template
sudo sed -e "s/INSTANCEID/${NAME}/g" -e "s/HOSTNAME/${NAME}.${DOMAIN}/g" ${METADATATEMPLATE} > ${METADATA}

# We generate the cloudinit iso
sudo rm -f ${CLOUDINITISO}
sudo genisoimage -input-charset iso8859-1 -output ${CLOUDINITISO} -volid cidata -joliet -rock ${USERDATA} ${METADATA}

# We copy the image and install it
sudo cp ${QCOWIMAGE} ${STORAGE}${NAME}.qcow2

sudo virt-install -n ${NAME} --memory 1024 --disk ${STORAGE}${NAME}.qcow2 --cdrom ${CLOUDINITISO} --noautoconsole --wait 1

exit 0
