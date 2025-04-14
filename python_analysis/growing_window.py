import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from tqdm import tqdm

import gen_utils as guts

'''
performs growing window analysis across two localizers

sorts voxels by significance values in loc_1
looks at response in loc_2
'''

subjs = ['kaneff01'] + [f'kaneff{lid:02d}' for lid in range(6,25)]

# sort voxels by loc_1
# measure response in loc_2
loc_1 = 'vis'
loc_2 = 'foss'

# loc_2 conditions. order is important!
conditions = ['Fa', 'O', 'Scr', 'S']

rois = ['FFA', 'OFA', 'STS', 'PPA', 'OPA', 'RSC']
contrasts = ['Fa-O', 'Fa-O', 'Fa-O', 'S-O', 'S-O', 'S-O']
parcelation = 'julian_parcels'
hemis = ['rh']

for rid in range(len(rois)):
    cols = ['subject', 'percent', 'condition', 'beta']
    df = pd.DataFrame(columns=cols)
    
    roi = rois[rid]
    contrast = contrasts[rid]
    
    for hemi in hemis:
        for subj in tqdm(subjs):
            parcel = gut.load_parcel(subj, parcellation, roi, hemi)
            pidx = np.where(parcel != 0)

            sigs = gut.load_sigs(subj, loc_1, contrast, 'all')
            sigs = sigs[pidx].squeeze()

            sidx = np.argsort(sigs)[::-1]

            all_betas = gut.load_betas(subj, loc_2, 'all')
            cond_betas = all_betas[pidx[0], pidx[1], pidx[2], :len(conditions)]
            cond_betas = cond_betas[sidx, :]

            num_voxels = cond_betas.shape[0]

            for N in range(1, 101):  # N% from 1 to 100
                top_N_voxels = int(np.ceil(N / 100 * num_voxels))  # Get top N% voxels
                running_means = {condition: np.mean(cond_betas[:top_N_voxels, cid]) for cid, condition in enumerate(conditions)}

                for condition, mean_beta in running_means.items():
                    df.loc[len(df)] = {'subject': subj, 'percent': N, 'condition': condition, 'beta': mean_beta}
