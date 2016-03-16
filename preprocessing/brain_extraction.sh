#!/bin/bash
#Script to extract the non-brain tissues from the dti volumes

NII_FOLDER=$1
ACQ=$2

#Read variables form config file
BET_THR=$3
NECK_RM=$4

# for vol in $LIST_DTI; do
  echo ""
  echo " ==> BET <=="
  if [[ `which fsl` == "" ]]; then
    echo "  Error: FSL is missing! Please intall FSL packages before using this script."
    exit
  fi

  echo ""
  if [[ "$NECK_RM" == "Y" ]]; then
    echo "    --> Using Bias and Neck removal option"
    bet $NII_FOLDER/${ACQ}_dti.nii.gz $NII_FOLDER/${ACQ}_brain -m -f $BET_THR -B
  else
    echo "    --> Using fast brain extraction procedure"
    bet $NII_FOLDER/${ACQ}_dti.nii.gz $NII_FOLDER/${ACQ}_brain -m -f $BET_THR
  fi

  # Remove the unnecessary dti brain extract volume
  rm $NII_FOLDER/${ACQ}_brain.nii.gz
# done
