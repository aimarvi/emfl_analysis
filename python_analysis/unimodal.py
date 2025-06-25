import os
import numpy as np
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import nibabel as nib

from tqdm import tqdm

import gen_utils as guts

save_dir = '../data/'
if not os.path.exists(save_dir):
    os.mkdir(save_dir)


# mapping of subjects across original and repeat experiments
subjs = {
    'kaneff01': 'kanderson05',
    'kaneff13': 'kanderson04',
    'kaneff14': 'kanderson01',
    'kaneff17': 'kanderson02',
    'kaneff18': 'kanderson03',
}
hemis = ['rh', 'lh']

vis_rois = ['vwfa', 'FFA', 'STS', 'PPA', 'EBA', 'OFA', 'OPA', 'RSC', 'LOC']
vis_contrasts = ['W-O', 'Fa-O', 'Fa-O', 'S-O', 'B-O','Fa-O', 'S-O','S-O','O-Scr']

vis_cond = ['Fa', 'S', 'B', 'O', 'W']
aud_cond = ['FB', 'FP', 'NW', 'QLT', 'MATH']

# only consider top N% of voxels
top_n_pc = 0.1

cols = ['subject', 'experiment', 'contrast', 'betas', 'hemi', 'parcel']
df = pd.DataFrame(columns=cols)

for roi in tqdm(vis_rois):
    for hemi in hemis:
        if roi == 'vwfa' and hemi == 'rh':
            continue
            
        for emfl, vis in subjs.items():
            if roi == 'vwfa':
                parcellation = 'vwfa_parcels'
            else:
                parcellation = 'julian_parcels'
                
            parcel = guts.load_parcel(emfl, parcellation, roi, hemi)
            contrast = vis_contrasts[vis_rois.index(roi)]

            # select top N% selective voxels, defined in the last 2 runs
            effloc_sigs = guts.load_sigs(emfl, 'vis', contrast, 'last')

            effloc_sigs_parcel = np.squeeze(effloc_sigs[parcel!=0])
            sorted_indices = np.argsort(effloc_sigs_parcel)[::-1]

            top_idxs = sorted_indices[:int(np.round(len(sorted_indices)*(top_n_pc)))]

            # betas from held-out runs of original, visual+audio stimuli
            # held-out are the first 3 runs
            alt_betas = guts.load_betas(emfl, 'vis', 'first')
            for i in range(len(vis_cond)):
                betas = alt_betas[:,:,:,i]
                betas_parcel = np.squeeze(betas[parcel!=0])
                betas_top = np.mean(betas_parcel[top_idxs])

                df.loc[len(df)] = {
                    'subject': emfl,
                    'experiment': 'emfl',
                    'contrast': vis_cond[i],
                    'betas': betas_top,
                    'hemi': hemi,
                    'parcel': roi          
                }

            # betas from repeat subjects with visual-only stimuli
            # 'all' because we only ran the first 3 runs
            vis_betas = guts.load_betas(vis, 'effloc', 'all')
            for i in range(len(vis_cond)):
                betas = vis_betas[:,:,:,i]
                betas_parcel = np.squeeze(betas[parcel!=0])
                betas_top = np.mean(betas_parcel[top_idxs])

                df.loc[len(df)] = {
                    'subject': emfl,
                    'experiment': 'vis',
                    'contrast': vis_cond[i],
                    'betas': betas_top,
                    'hemi': hemi,
                    'parcel': roi      
                }

df.to_pickle(os.path.join(save_dir, 'uni_EMFL-select.pkl'))
