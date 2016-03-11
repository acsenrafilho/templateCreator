#!/bin/bash
#Script to list all the folders that will be used to build the brain template

FOLDER_PATH=$1
FOLDERS=`ls $1`

if [[ -d "$FOLDER_PATH/log" ]]; then
    rm -R $FOLDER_PATH/log
    mkdir $FOLDER_PATH/log
fi
mkdir $FOLDER_PATH/log

#Showing the folders name
echo "Folders used to the template:"
for f in $FOLDERS; do
  if [[ "$f" != "log" ]]; then
    echo $f
    echo $f >> $FOLDER_PATH/log/DICOM_folders.log
  fi
done

echo "=== List of folder saved in log/DICOM_folders.log ==="
