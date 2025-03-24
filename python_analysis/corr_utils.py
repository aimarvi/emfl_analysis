import os
import nibabel as nib
import numpy as np

from scipy import stats
from scipy.stats import norm
from tqdm import tqdm

from gen_utils import *

def get_correlations(subj, roi, hemi, parcellation, loc_1, contrast_1, within=True, loc_2=None, contrast_2=None, full=False):
'''
returns the split-half reliability between or within localizers

args:
    subj (str): subject name
    roi (str): fROI name (eg. 'FFA')
    hemi (str): hemisphere. one of ['lh', 'rh']
    parcellation (str): dir of parcels (eg. 'julian_parcels')
    loc_1 (str): localizer name (eg. 'vis', 'aud')
    contrast_1 (str): contrast name (eg. 'Fa-O')
    within (bool): if True, within localizer split-half. 

  if within:
    loc_2 (str): localizer name (eg. 'foss')
    contrast_2 (str): contrast name (eg. 'Fa-O')
    full (bool): if True, control for even-odd splits in between-localizer comparison

returns:
    (dict): changes based on args. 
'''

    if within: #split-half

        #load and parcellate the data
        parcel = load_parcel(subj, parcellation, roi, hemi)
        sigs_even = load_sigs(subj, loc_1, contrast_1, 'even')
        sigs_odd = load_sigs(subj, loc_1, contrast_1, 'odd')
        sigs_even_parcel = np.squeeze(sigs_even[parcel!=0])
        sigs_odd_parcel = np.squeeze(sigs_odd[parcel!=0])
        

        #calculate and transform the correlations
        corr = stats.pearsonr(sigs_even_parcel, sigs_odd_parcel)
        r_val = corr.statistic
        p_val = corr.pvalue
        r_trans_val = np.arctanh(r_val)
        return({'r':r_val, 'p':p_val, 'r_trans':r_trans_val, 'even':sigs_even_parcel, 'odd':sigs_odd_parcel})
        
        
    elif (not within) and (not full): #across localizers
        #load and parcellate the data
        parcel = load_parcel(subj, parcellation, roi, hemi)
        sigs_loc_1 = load_sigs(subj, loc_1, contrast_1, 'all')
        sigs_loc_2 = load_sigs(subj, loc_2, contrast_2, 'all')
        sigs_loc_1_parcel = np.squeeze(sigs_loc_1[parcel!=0])
        sigs_loc_2_parcel = np.squeeze(sigs_loc_2[parcel!=0])

        #calculate and transform the correlations
        corr = stats.pearsonr(sigs_loc_1_parcel, sigs_loc_2_parcel)
        r_val = corr.statistic
        p_val = corr.pvalue
        r_trans_val = np.arctanh(r_val)
        return({'r':r_val, 'p':p_val, 'r_trans':r_trans_val, 'loc_1':sigs_loc_1_parcel, 'loc_2':sigs_loc_2_parcel})

    elif (not within) and full:
        
        parcel = load_parcel(subj, parcellation, roi, hemi)
        
        sigs_loc_1_even = load_sigs(subj, loc_1, contrast_1, 'even')
        sigs_loc_1_parcel_even = np.squeeze(sigs_loc_1_even[parcel!=0])
        
        sigs_loc_1_odd = load_sigs(subj, loc_1, contrast_1, 'odd')
        sigs_loc_1_parcel_odd = np.squeeze(sigs_loc_1_odd[parcel!=0])
        
        sigs_loc_2_even = load_sigs(subj, loc_2, contrast_2, 'even')
        sigs_loc_2_parcel_even = np.squeeze(sigs_loc_2_even[parcel!=0])
        
        sigs_loc_2_odd = load_sigs(subj, loc_2, contrast_2, 'odd')
        sigs_loc_2_parcel_odd = np.squeeze(sigs_loc_2_odd[parcel!=0])

        corr_loc_1_within = stats.pearsonr(sigs_loc_1_parcel_even, sigs_loc_1_parcel_odd)
        r_loc_1_within = corr_loc_1_within.statistic
        p_loc_1_within = corr_loc_1_within.pvalue
        r_trans_loc_1_within = np.arctanh(r_loc_1_within)

        corr_loc_2_within = stats.pearsonr(sigs_loc_2_parcel_even, sigs_loc_2_parcel_odd)
        r_loc_2_within = corr_loc_2_within.statistic
        p_loc_2_within = corr_loc_2_within.pvalue
        r_trans_loc_2_within = np.arctanh(r_loc_2_within)

        corr_across_even = stats.pearsonr(sigs_loc_1_parcel_even, sigs_loc_2_parcel_even)
        r_across_even = corr_across_even.statistic
        p_across_even = corr_across_even.pvalue
        r_trans_across_even = np.arctanh(r_across_even)

        corr_across_even_odd = stats.pearsonr(sigs_loc_1_parcel_even, sigs_loc_2_parcel_odd)
        r_across_even_odd = corr_across_even_odd.statistic
        p_across_even_odd = corr_across_even_odd.pvalue
        r_trans_across_even_odd = np.arctanh(r_across_even_odd)

        corr_across_odd = stats.pearsonr(sigs_loc_1_parcel_odd, sigs_loc_2_parcel_odd)
        r_across_odd = corr_across_odd.statistic
        p_across_odd = corr_across_odd.pvalue
        r_trans_across_odd = np.arctanh(r_across_odd)
        
        corr_across_odd_even = stats.pearsonr(sigs_loc_1_parcel_odd, sigs_loc_2_parcel_even)
        r_across_odd_even = corr_across_odd_even.statistic
        p_across_odd_even = corr_across_odd_even.pvalue
        r_trans_across_odd_even = np.arctanh(r_across_odd_even)
        
        across_r = np.mean([r_across_even, r_across_odd, r_across_even_odd, r_across_odd_even])
        r_trans_val = np.arctanh(across_r)

        return({'loc_1':r_loc_1_within, 'loc_2':r_loc_2_within, 'across':across_r, 'r_trans':r_trans_val})

    else:
        print('please specify valid conditions!')
        return None
        
        
def sort_voxels_for_growing_window(subj, roi, hemi, parcellation, localizer, contrast, conds):
'''
growing window analysis within a localizer. 
average beta weights of voxels as a function of ROI size, sorted by contrast significance in held-out runs

args:
    subj (str): subject name
    roi (str): fROI name (eg. 'FFA')
    hemi (str): hemisphere. one of ['lh', 'rh']
    parcellation (str): dir of parcels (eg. 'julian_parcels')
    localizer (str): localizer name (eg. 'vis', 'aud')
    contrast (str): contrast whose significance to sort by (eg. 'Fa-O')
    conds (list[str]): all localizer conditions, in paradigm order (eg. ['Fa', 'S', 'B', 'O', 'W'])

returns:
    (dict): sigs (dict), betas (dict)
'''

    #load the data
    parcel = load_parcel(subj, parcellation, roi, hemi)
    sigs_even = load_sigs(subj, localizer, contrast, 'even')
    betas_odd = load_betas(subj, localizer, 'odd')
    sigs_even_parcel = np.squeeze(sigs_even[parcel!=0])

    #get sorted indices by ranking voxels in contrast significance
    indices = np.argsort(sigs_even_parcel)[::-1]
    betas_conditions = {}
    for cid in range(len(conds)):
        betas_cond = np.squeeze(betas_odd[:,:,:,cid])
        betas_cond_parcel = np.squeeze(betas_cond[parcel!=0])
        betas_sorted = betas_cond_parcel[indices]
        
        #average over top N betas for every N
        windows = np.arange(1, len(indices), 1)
        avg_betas = []
        for w in windows:
            vals = betas_sorted[:w]
            avg_betas.append(np.mean(vals))
        betas_conditions[conds[cid]] = avg_betas
        
    sigs_sorted = sigs_even_parcel[indices]
    return({'sigs':sigs_sorted, 'betas':betas_conditions})
    

def sort_voxels_gw_across_localizers(subj, roi, hemi, parcellation, loc_1, contrast_1, loc_2, conds_2):
'''
growing window analysis between two localizers
average beta weights of voxels as a function of ROI size, sorted by contrast significance in held-out runs of another localizer

args:
    subj (str): subject name
    roi (str): fROI name (eg. 'FFA')
    hemi (str): hemisphere. one of ['lh', 'rh']
    parcellation (str): dir of parcels (eg. 'julian_parcels')
    loc_1 (str): localizer name (eg. 'vis', 'aud')
    contrast_1 (str): contrast in localizer 1 whose significance to sort by (eg. 'Fa-O')
    loc_2 (str): localizer name (eg. 'foss')
    conds_2 (list[str]): all conditions in localizer 2 (eg. ['Fa', 'O', 'Scr', 'S'])

returns:
    (dict): sigs (dict), betas (dict)
'''

    #load the data
    parcel = load_parcel(subj, parcellation, roi, hemi)
    sigs = load_sigs(subj, loc_1, contrast_1, 'all')
    betas = load_betas(subj, loc_2, 'all')
    sigs_parcel = np.squeeze(sigs[parcel!=0])

    #get sorted indices by ranking voxels in contrast significance
    indices = np.argsort(sigs_parcel)[::-1]
    betas_conditions = {}
    for cid in range(len(conds_2)):
        betas_cond = np.squeeze(betas[:,:,:,cid])
        betas_cond_parcel = np.squeeze(betas_cond[parcel!=0])
        betas_sorted = betas_cond_parcel[indices]

        windows = np.arange(1,len(indices), 1)
        avg_betas = []
        for w in windows:
            vals = betas_sorted[:w]
            avg_betas.append(np.mean(vals))
        betas_conditions[conds_2[cid]] = avg_betas

    sigs_sorted = sigs_parcel[indices]
    return ({'sigs':sigs_sorted, 'betas':betas_conditions})
