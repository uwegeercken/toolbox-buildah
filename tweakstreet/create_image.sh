#!/bin/bash
#
# Script to create a OCI compliant image for the Tweakstreet ETL tool using buildah.
#
# The script prepares a base image which then can be used as a blueprint for other images. It pulls the version specified in "tweakstreet_version" from the Tweakstreet website. An image using this blueprint can copy all required flows, modules and data files to the /home/tweakstreet/flows folder
#
# A user "tweakstreet" with UID=101 and GID=101, which owns the programs files and the /home/tweakstreet folder and files is created.
#
# Following folders are available:
# - the Tweakstreet ETL tool root folder: /opt/tweakstreet
# - folder for JDBC drivers: /home/tweakstreet/.tweakstreet/drivers
# - folder for dataflows, control flows, modules, etc: /home/tweakstreet/flows
#
# The /opt/tweakstreet/bin folder where the shell script to run flows - engine.sh - is located, is available on the path.
#
# last update: uwe.geercken@web.de - 2022-01-05
#

# base image
toolbox_image=fedora-toolbox:35

# new image
image_name="tweakstreet"
image_version="1.19.7"
image_format="docker"
image_author="Uwe Geercken"

folder_downloads="/var/home/uwe/Downloads"
tweakstreet_download_url="https://updates.tweakstreet.io/updates"
tweakstreet_download_filename="Tweakstreet-${image_version}-portable.tar.gz"
tweakstreet_target_folder="/opt/tweakstreet"

working_container="${image_name}-working-container"

# start of build

# create the working container
container=$(buildah --name "${working_container}" from ${toolbox_image})

# if the Tweakstreet application download for the selected version is not present, download it
if [ ! -f "${folder_downloads}/${tweakstreet_download_filename}" ]
then
  curl "${tweakstreet_download_url}/${tweakstreet_download_filename}" --output "${folder_downloads}/${tweakstreet_download_filename}"
fi

# untar the Tweakstreet ETL tool archive file
tar -xf "${folder_downloads}/${tweakstreet_download_filename}" --directory "./temp"

# copy tweakstreet application files
buildah copy $container "./temp/Tweakstreet-${image_version}-portable" "${tweakstreet_target_folder}"

# install additional packages
buildah run $container dnf -y -q install libxshmfence nss atk at-spi2-atk libdrm gdk-pixbuf2 gtk3 libgbm
buildah run $container dnf clean all

# config
buildah config --author="${image_author}" $container
buildah config --workingdir "${tweakstreet_target_folder}" $container

# commit container, create image
#buildah commit --format "${image_format}" $container "${image_name}:${image_version}"
buildah commit $container "${image_name}:${image_version}"

# remove working container
buildah rename $container "${image_name}:${image_version}"

# remove the Tweakstreet ETL tool local folder
#if [ ! -z ${tweakstreet_download_folder+x} ]
#then
#	rm -rf ${tweakstreet_download_folder}
#fi
