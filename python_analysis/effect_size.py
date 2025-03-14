import os
import numpy as np
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import nibabel as nib

from tqdm import tqdm

import gen_utils as guts

# order is specific to efficient localizer paradigm
vis_cond = ['Fa', 'S', 'B', 'O', 'W']
aud_cond = ['FB', 'FP', 'NW', 'QLT', 'MATH']

# subject ids
subjs = ['kaneff01'] + [f'kaneff{sid:02d}' for sid in range(6,25)]

# which runs and fROIs to analyze
exp_name = 'vis'
ortho_exp_name = 'aud'
hemis = ['rh', 'lh']
run_sets = ['even', 'odd']

vis_rois = ['vwfa', 'FFA', 'STS', 'PPA', 'EBA', 'OFA', 'OPA', 'RSC', 'LOC']
vis_contrasts = ['W-O', 'Fa-O', 'Fa-O', 'S-O', 'B-O','Fa-O', 'S-O','S-O','O-Scr']

cols = ['subject', 'contrast', 'betas', 'hemi', 'parcel']
df = pd.DataFrame(columns=cols)

# only consider the top N% of selective voxels
top_n_pc = 0.1

for roi in tqdm(vis_rois):
    for hemi in hemis:

        # vwfa is left hemi only
        if roi == 'vwfa' and hemi == 'rh':
            continue

        # use separate parcellation for vwfa parcels (from Saygin)
        for subj in subjs:
            if roi == 'vwfa':
                parcellation = 'vwfa_parcels'
            else:
                parcellation = 'julian_parcels'

            for runs in run_sets:
                # select voxels using a subset of runs and measure selectivity in held-out runs
                held_out = 'odd' if runs == 'even' else 'even'

                # consider only the top N% of voxels within an anatomical parcel
                parcel = guts.load_parcel(subj, parcellation, roi, hemi)
                contrast = vis_contrasts[vis_rois.index(roi)]
                effloc_sigs = guts.load_sigs(subj, exp_name, contrast, runs)

                effloc_sigs_parcel = np.squeeze(effloc_sigs[parcel!=0])
                sorted_indices = np.argsort(effloc_sigs_parcel)[::-1]

                top_idxs = sorted_indices[:int(np.round(len(sorted_indices)*(top_n_pc)))]

                # get betas in held-out runs
                alt_betas = guts.load_betas(subj, exp_name, held_out)
                for i in range(len(vis_cond)):
                    betas = alt_betas[:,:,:,i]
                    betas_parcel = np.squeeze(betas[parcel!=0])
                    betas_top = np.mean(betas_parcel[top_idxs])

                    df.loc[len(df)] = {
                        'subject': subj,
                        'contrast': vis_cond[i],
                        'betas': betas_top,
                        'hemi': hemi,
                        'parcel': roi          
                    }

                more_betas = guts.load_betas(subj, ortho_exp_name, held_out)
                for i in range(len(aud_cond)):
                    betas = more_betas[:,:,:,i]
                    betas_parcel = np.squeeze(betas[parcel!=0])
                    betas_top = np.mean(betas_parcel[top_idxs])

                    df.loc[len(df)] = {
                        'subject': subj,
                        'contrast': aud_cond[i],
                        'betas': betas_top,
                        'hemi': hemi,
                        'parcel': roi      
                    }
