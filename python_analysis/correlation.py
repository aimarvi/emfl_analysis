import os
import numpy as np
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import nibabel as nib

from scipy import stats
from scipy.stats import norm
from tqdm import tqdm

import corr_utils as cuts

'''
calculates correlation (pearson's r) of voxel activity between two localizers
@aimarvi
'''

subjs = ['kaneff01'] + [f'kaneff{sid:02d}' for sid in range(6,25)]
alt_subjs = [f'kaneff{sid:02d}' for sid in range(9,25)]

hemis = ['lh', 'rh']
rois = ['FFA', 'OFA', 'STS', 'PPA', 'OPA', 'RSC', 'LOC', 'EBA', 'vwfa']
loc_1 = 'vis';
contrast_1s = ['Fa-O', 'Fa-O', 'Fa-O', 'S-O', 'S-O', 'S-O', 'O-Scr', 'B-O', 'W-O']; contrast_2s = ['Fa-O', 'Fa-O', 'Fa-O', 'S-O', 'S-O', 'S-O', 'O-Scr', 'B-O', 'W-O', 'Fa-O'];

cols = ['subject', 'contrast', 'loc_1', 'loc_2', 'across', 'across_uncorrected', 'r_trans']
df = pd.DataFrame(columns=cols)

for i in range(len(rois)):
    for hemi in hemis:
        roi = rois[i]; contrast_1 = contrast_1s[i]; contrast_2 = contrast_2s[i]
        parcellation = 'julian_parcels'
        loc_2 = 'foss'
        todo = subjs
        if roi == 'EBA':
            loc_2 = 'ebavwfa'
            todo = alt_subjs
        elif roi =='vwfa':
            loc_2 = 'ebavwfa'; hemi = 'lh'; parcellation = 'vwfa_parcels'
            todo = alt_subjs
        for subj in todo:
            try:
                result = cuts.get_correlations(subj, roi, hemi, parcellation, loc_1, contrast_1, within=False, loc_2=loc_2, contrast_2=contrast_2, full=True)
                res2 = cuts.get_correlations(subj, roi, hemi, parcellation, loc_1, contrast_1, within=False, loc_2=loc_2, contrast_2=contrast_2, full=False)
                df.loc[len(df)] = {'subject': subj,  
                                   'contrast': roi,
                                   'loc_1': result['loc_1'],  
                                   'loc_2': result['loc_2'],
                                   'across': result['across'],
                                   'across_uncorrected': res2['r'],
                                  'r_trans': result['r_trans']}

            except Exception as e:
                print(subj, e)
