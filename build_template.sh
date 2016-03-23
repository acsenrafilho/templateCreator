#!/bin/bash

usage(){
  echo "The template creator is a group of shell scripts to build a population brian template. At this point, the scripts are able to build only DTI templates."
  echo "Usage: $0 <DICOM path>"
  echo ""
  echo  "DICOM path = The path where is a structured folder with all the subjects for the template creation. Please, set the folder as:"
  echo "DICOM"
  echo "  -> subject1"
  echo "    -> DTI DICOM folder 1 (all the DICOM images that compose one single DTI acquisition)"
  echo "    -> DTI DICOM folder 2"
  echo "    -> ..."
  echo "    -> DTI DICOM folder n"
}

if [[ $# -eq 0 ]]; then
  usage
  exit
fi

#Selecting and listing the folders passed to build the brain template.
source config/folder_list.sh $1

#Turn the folders name in anonymous style
source config/anonym_subjects.sh $1

for subj in `ls $1 | grep "subj*"`; do
  echo "***********************************************************************"
  echo "*********** DTI normalization from $subj initiated ************"
  echo "***********************************************************************"
  echo ""
  echo "*** Initial process to create a brain template ***"
  echo ""
  echo "Step 1: Converting DICOM to Nifti"

  # Apply dcm2nii to create the nii files from the DICOM FOLDERS
  # Starting to select each subject to do all the process.
  source config/dcm2nii.sh $1 $subj

  # nii folder has all the images to process
  NII_FOLDER=$1/$subj/nii

  # Split the pre processing procedures to each acquisition per time. Less consumption of time per volume.
  for acq in `ls $NII_FOLDER | grep .nii.gz | cut -c1-11`; do
    echo "Step 2: Pre processing DWIs volumes: Brain extraction and eddy correction - Folder: `echo ${acq} | cut -c4-11`"
    # Show the parameters choosen: registration (flirt -> DOF (affine, 6 dof, 3 dof), fnirt (warpsize, fhwmin, fwhmref, subsamp, ))
    # Read conf file with the variables values.
    echo "  --> Creating brain mask..."
    BET_THR=`cat config/config_var.conf | grep BET_THR= | cut -c9-12`
    NECK_RM=`cat config/config_var.conf | grep NECK_RM= | cut -c9-10`
    source preprocessing/brain_extraction.sh $NII_FOLDER $acq $BET_THR $NECK_RM

    echo "  --> Eddy current correction procedure..."
    HIGH_PERF=`cat config/config_var.conf | grep HIGH_PERF= | cut -c11-12`
    source preprocessing/eddy_correction.sh  $NII_FOLDER $acq $HIGH_PERF
  done

    echo "Step 3: Registration procedure:"
    echo "  --> Intrasubject registration"
    DOF=`cat config/config_var.conf | grep DOF | cut -c5-6`
    source preprocessing/reg_intrasubj.sh $NII_FOLDER $DOF

    echo "  --> Spatial normalization - Registration with MNI template"
    MNI=`cat config/config_var.conf | grep MNI= | cut -c5-20`
    BET_THR=`cat config/config_var.conf | grep BET_THR= | cut -c9-12`
    WARP=`cat config/config_var.conf | grep WARP= | cut -c6-12`
    INFWHM=`cat config/config_var.conf | grep INFWHM= | cut -c8-11`
    REFFWHM=`cat config/config_var.conf | grep REFFWHM= | cut -c9-12`
    SUBSAMP=`cat config/config_var.conf | grep SUBSAMP= | cut -c9-17`
    source preprocessing/reg_standard $NII_FOLDER $MNI $BET_THR $WARP $INFWHM $REFFWHM $SUBSAMP

    echo "***********************************************************************"
    echo "*** DTI normalization from $subj terminated with success.***"
    echo "***********************************************************************"
    echo ""
    echo ""
done

    echo "Step 4: Merge all subjects to build a final brain template"
    if [[ `ls $1 | grep template` == "" ]]; then
      mkdir $1/template
    fi
    for subj in `ls $1 | grep subj`; do
      cp $1/$subj/nii/dti_ec_corr_mean_nlin.nii.gz $1/template
      mv $1/template/dti_ec_corr_mean_nlin.nii.gz $1/template/dti_$subj.nii.gz
    done
    source postprocessing/merge_temp $1/template
