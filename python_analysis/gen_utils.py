import os
import nibabel as nib
import numpy as np

def nifti_from_path(path):
'''
wrapper function to easily load in fMRI data (*.nii, *.mgz, etc)

args:
    path (str): path to data file

returns:
    (nd.array): data in array format
'''
    #get data from nifti file, load as numpy array
    nifti = nib.load(path).dataobj
    data = np.array(nifti)
    return data

def load_sigs(subj, exp, contrast, split):
'''
load in the significance values for a given contrast

args:
    subj (str): subject name
    exp (str): localizer name (eg. 'vis', 'aud')
    contrast (str): functional contrast (eg. 'Fa-O')
    split (str): which runs did the analysis use? One of ['all', 'even', 'odd']

returns:
    (nd.array): data in array format
'''
    if exp == 'ebavwfa':
        subj = f'{subj}b'
    #load with nibabel to numpy
    path = f'../vols_{exp}/{subj}/bold/{exp}.sm3.{split}/{contrast}/sig.nii.gz'
    return nifti_from_path(path)

def load_betas(subj, exp, split):
'''
load in all GLM beta values

args:
    subj (str): subject name
    exp (str): localizer name (eg. 'vis', 'aud')
    split (str): which runs did the analysis use? One of ['all', 'even', 'odd']

returns:
    (nd.array): data in array format
'''
    if exp == 'ebavwfa':
        subj = f'{subj}b' # ebavwfa localizer was run during a second localizer

    path = f'../vols_{exp}/{subj}/bold/{exp}.sm3.{split}/beta.nii.gz'
    return nifti_from_path(path)

def load_parcel(subj, parcellation, roi, hemi):
'''
load in anatomical parcel transformed to the subject's native space

args:
    subj (str): subject name
    parcellation (str): dir name holding the parcels (eg. 'julian_parcels')
    roi (str): functional roi for which parcel is defined (eg. 'FFA')
    hemi (str): hemisphere. one of ['lh', 'rh']

returns:
    (nd.array): parcel in native space, indicated by non-zero values
'''
    #because MD has so many parcels, want to get groups
    def md_macroparcels(subj):
        
        md_macro_parcels = {}
    
        parcels_list = [p for p in os.listdir(f'../data_analysis/masks/vols/{subj}/md_parcels') if 'functional' in p and 'surf' not in p]
        frontals = [p for p in parcels_list if 'Frontal' in p]
        parietals = [p for p in parcels_list if 'Parietal' in p]
    
        r_frontals = [p for p in frontals if p[0] == 'r']
        l_frontals = [p for p in frontals if p[0] == 'l']
        r_parietals = [p for p in parietals if p[0] == 'r']
        l_parietals = [p for p in parietals if p[0] == 'l']
    
        for i in range(len([r_frontals, l_frontals, r_parietals, l_parietals])):
    
            #construct macro-parcels from sub-parcels
            group = [r_frontals, l_frontals, r_parietals, l_parietals][i]
            group_parcel = np.zeros((104,104,52))
            for parcel in group:
                parcel_path = f'../data_analysis/masks/vols/{subj}/md_parcels/{parcel}'
                sub_parcel = nifti_from_path(parcel_path)
                group_parcel = group_parcel + sub_parcel
    
            if i == 0:
                md_macro_parcels['r_frontal'] = group_parcel
            elif i == 1:
                md_macro_parcels['l_frontal'] = group_parcel
            elif i == 2:
                md_macro_parcels['r_parietal'] = group_parcel
            elif i == 3:
                md_macro_parcels['l_parietal'] = group_parcel
                
        return md_macro_parcels
    
    #get correct file name format
    if parcellation == 'md_parcels':
        
        parcels = md_macroparcels(subj)
        roi_str = f'{hemi[0]}_{roi}'
        return parcels[roi_str]

    elif parcellation == 'fs_dkt':
        path = f'../recons/{subj}/mri/FSatlas_functional.nii.gz'
        return nifti_from_path(path)
        
    else:
        
        if parcellation == 'julian_parcels':
            roi = f'{hemi[0]}{roi}_functional.nii.gz'
        elif parcellation == 'lang_parcels':
            roi = f'{roi}.nii'
        elif parcellation == 'ToM_parcels':
            roi = f'{roi}_xyz.nii.gz'
        elif parcellation == 'vwfa_parcels':
            roi = f'l{roi}_functional.nii.gz'
        elif parcellation == 'speech_parcels_v2':
            roi = f'lang_speech_LH_1_5_mirrored_conjunction_final.nii'
            
        #load with nibabel to numpy
        path = f'../data_analysis/masks/vols/{subj}/{parcellation}/{roi}'
        return nifti_from_path(path)
