import numpy as np
import pandas as pd
import nibabel as nib
import seaborn as sns
import matplotlib.pyplot as plt

from tqdm import tqdm

import gen_utils as guts

'''
script for obtaining the data for OMNIBUS and within-ROI ANOVA
see perform_anova.py for doing the actual ANOVA
'''

subjs = ['kaneff01'] + [f'kaneff{sid:02d}' for sid in range(6,25)]

hemis = ['rh', 'lh']
rois = ['FFA', 'OFA', 'STS', 'PPA', 'OPA', 'RSC', 'LOC']
contrasts = ['Fa-O', 'Fa-O', 'Fa-O', 'S-O','S-O','S-O', 'O-Scr']

run_sets = ['even', 'odd']
exps = ['efficient', 'standard']

parcellation = 'julian_parcels'
top_n_pc = 0.1

cols = ['subject', 'definer', 'measurer', 'contrast', 'betas', 'hemi', 'parcel']
df = pd.DataFrame(columns=cols)

for roi in tqdm(rois):
    for hemi in hemis:
        for subj in subjs:
            for runs in run_sets:
                held_out = 'odd' if runs == 'even' else 'even'
                
                for definer in exps:
                    other = 'standard' if definer=='efficient' else 'efficient'
                    if definer=='efficient':
                        exp = 'vis'
                        alt_exp = 'foss'
                        conds = ['Fa', 'S', 'B', 'O', 'W']
                        alt_conds = ['Fa', 'O', 'Scr', 'S']
                    else:
                        exp = 'foss'
                        alt_exp = 'vis'
                        conds = ['Fa', 'O', 'Scr', 'S']
                        alt_conds = ['Fa', 'S', 'B', 'O', 'W']
                    
                    
                    parcel = guts.load_parcel(subj, parcellation, roi, hemi)
                    contrast = contrasts[rois.index(roi)]
                    effloc_sigs = guts.load_sigs(subj, exp, contrast, runs)

                    effloc_sigs_parcel = np.squeeze(effloc_sigs[parcel!=0])
                    sorted_indices = np.argsort(effloc_sigs_parcel)[::-1]

                    top_idxs = sorted_indices[:int(np.round(len(sorted_indices)*(top_n_pc)))]

                    alt_betas = guts.load_betas(subj, exp, held_out)
                    
                    for i in range(len(conds)):
                        betas = alt_betas[:,:,:,i]
                        betas_parcel = np.squeeze(betas[parcel!=0])
                        betas_top = np.mean(betas_parcel[top_idxs])

                        df.loc[len(df)] = {
                            'subject': subj,
                            'definer': definer,
                            'measurer': definer,
                            'contrast': conds[i],
                            'betas': betas_top,
                            'hemi': hemi,
                            'parcel': roi          
                        }

                    more_betas = guts.load_betas(subj, alt_exp, held_out)
                    for i in range(len(alt_conds)):
                        betas = more_betas[:,:,:,i]
                        betas_parcel = np.squeeze(betas[parcel!=0])
                        betas_top = np.mean(betas_parcel[top_idxs])

                        df.loc[len(df)] = {
                            'subject': subj,
                            'definer': definer,
                            'measurer': other,
                            'contrast': alt_conds[i],
                            'betas': betas_top,
                            'hemi': hemi,
                            'parcel': roi      
                        }
                        
df1 = df
