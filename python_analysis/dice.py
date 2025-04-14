import numpy as np
import pandas as pd

import gen_utils as guts

def compute_dice(sigs_1, sigs_2, label, df):
'''
Helper function to compute Dice coefficients
'''
    sidx_1 = np.argsort(sigs_1)[::-1]
    sidx_2 = np.argsort(sigs_2)[::-1]

    assert len(sidx_1) == len(sidx_2)
    num_voxels = len(sidx_1)

    for perc in percentages:
        k = int(num_voxels * perc)
        set_1 = set(sidx_1[:k])
        set_2 = set(sidx_2[:k])

        intersection = len(set_1 & set_2)
        dice = (2 * intersection) / (len(set_1) + len(set_2))

        df.loc[len(df)] = {'Subject': subj, 'ROI': roi, 'Experiment': label, 'Percent': perc, 'Dice': dice}
    return df

subjs = ['kaneff01'] + [f'kaneff{lid:02d}' for lid in range(6,25)]
localizers = ['vis', 'foss']

contrasts = ['Fa-O', 'Fa-O', 'Fa-O', 'S-O', 'S-O', 'S-O', 'O-Scr']
rois = ['FFA', 'OFA', 'STS', 'PPA', 'OPA', 'RSC', 'LOC']
hemi = 'rh'
ps = ['julian_parcels'] * len(contrasts)

cols = ['Subject', 'ROI', 'Experiment', 'Percent', 'Dice']
df1 = pd.DataFrame(columns=cols)

for ridx in range(len(rois)):
    hemi = 'rh'
    roi = rois[ridx]
    contrast = contrasts[ridx]
    parcellation = ps[ridx]

    for subj in subjs:
        try:
            # Load and apply parcel
            parcel = guts.load_parcel(subj, parcellation, roi, hemi)
            pidx = np.where(parcel != 0)

            percentages = np.arange(0.1, 1.1, 0.1)

            # ----- Within-localizer Dice -----
            for exp, label in zip(localizers, ['loc_1', 'loc_2']):
                sigs_even = guts.load_sigs(subj, exp, contrast, 'even')[pidx].squeeze()
                sigs_odd = guts.load_sigs(subj, exp, contrast, 'odd')[pidx].squeeze()

                df1 = compute_dice(sigs_even, sigs_odd, label, df1)

            # ----- Between-localizer Dice -----
            if corrected:
                for run_1 in ['even', 'odd']:
                    for run_2 in ['even', 'odd']:
                        sigs_loc_1 = guts.load_sigs(subj, localizers[0], contrast, run_1)[pidx].squeeze()
                        sigs_loc_2 = guts.load_sigs(subj, localizers[1], contrast, run_2)[pidx].squeeze()

                        df1 = compute_dice(sigs_loc_1, sigs_loc_2, 'between', df1)

            else:
                sigs_loc_1 = guts.load_sigs(subj, localizers[0], contrast, 'all')[pidx].squeeze()
                sigs_loc_2 = guts.load_sigs(subj, localizers[1], contrast, 'all')[pidx].squeeze()

                df1 = compute_dice(sigs_loc_1, sigs_loc_2, 'between', df1)

        except Exception as e:
            print(subj, e)
