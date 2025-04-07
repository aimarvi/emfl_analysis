import numpy as np
import pandas as pd

import gen_utils as guts

'''
count the number of subjects (out of 20) who show at least N number of significant voxels
'''


subjs = ['kaneff01'] + [f'kaneff{n:02d}' for n in range(6,25)]

localizer = 'audHalf'
parcellation = 'ToM_parcels'
runs_set = ['odd', 'all']
thresholds = [3, 10]

rois = ['RTPJ']
contrasts = ['FB-FP']
hemis = ['rh']

cols = ['experiment', 'roi', 'hemi', 'threshold', 'runs', 'count', 'num-sigs', 'psize', 'category']
sum_df = pd.DataFrame(columns=cols)

for thresh in thresholds:
    for runs in runs_set:
        for hemi in hemis:
            for rid in range(len(rois)):
                roi = rois[rid]
                contrast = contrasts[rid]

                all_count = 0
                avg_sig_voxels = []
                avg_parcel_voxels = []
                for subj in subjs:
                    try:
                        # load in parcel
                        parcel = guts.load_parcel(subj, parcellation, roi, hemi)
                        pidx = np.where(parcel != 0)

                        # load in p-values using specified runs
                        sigs = guts.load_sigs(subj, localizer, contrast, runs)
                        sigs = sigs[pidx].squeeze()

                        # how many voxels reach at least p<0.001
                        count = np.sum(sigs>3)
                        if count<thresh:
                            all_count += 1

                        # average size of subj-specific parcel
                        p_size = np.sum(parcel != 0)
                        avg_sig_voxels.append(count)
                        avg_parcel_voxels.append(p_size)

                    except Exception as e:
                        print(subj, e)

                sum_df.loc[len(sum_df)] = {
                    'experiment': localizer,
                    'roi': roi,
                    'hemi': hemi,
                    'threshold': thresh,
                    'runs': runs,
                    'count': len(subjs) - all_count,
                    'num-sigs': np.mean(np.array(avg_sig_voxels)),
                    'psize': np.mean(np.array(avg_parcel_voxels)),
                    'category': 'efficient'
                }
