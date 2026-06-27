import numpy as np
import pandas as pd
from tqdm import tqdm

import gen_utils as utils


def main():
    """
    Collect beta data for omnibus and within-roi ANOVAs.

    Returns:
        pd.DataFrame:
            results_df (pd.DataFrame):
                One row per subject, definer, measurer, condition, hemisphere, and parcel.
    """

    subjects = ["kaneff01"] + [f"kaneff{subject_id:02d}" for subject_id in range(6, 25)]
    hemispheres = ["rh", "lh"]
    rois = ["FFA", "OFA", "STS", "PPA", "OPA", "RSC", "LOC"]
    contrasts = ["Fa-O", "Fa-O", "Fa-O", "S-O", "S-O", "S-O", "O-Scr"]
    run_sets = ["even", "odd"]
    definers = ["efficient", "standard"]
    top_fraction = 0.1

    rows = []

    for roi_name in tqdm(rois):
        contrast_name = contrasts[rois.index(roi_name)]

        for hemisphere_name in hemispheres:
            for subject_name in subjects:
                parcel_mask = utils.load_parcel(
                    subj=subject_name,
                    parcellation="julian",
                    roi=roi_name,
                    hemi=hemisphere_name,
                )
                parcel_index = parcel_mask != 0

                for run_label in run_sets:
                    held_out_label = "odd" if run_label == "even" else "even"

                    for definer_name in definers:
                        other_name = "standard" if definer_name == "efficient" else "efficient"
                        if definer_name == "efficient":
                            exp_name = "vis"
                            alt_exp_name = "foss"
                            condition_names = ["Fa", "S", "B", "O", "W"]
                            alt_condition_names = ["Fa", "O", "Scr", "S"]
                        else:
                            exp_name = "foss"
                            alt_exp_name = "vis"
                            condition_names = ["Fa", "O", "Scr", "S"]
                            alt_condition_names = ["Fa", "S", "B", "O", "W"]

                        sig_values = utils.load_sigs(subject_name, exp_name, contrast_name, run_label)
                        sig_values_parcel = np.squeeze(sig_values[parcel_index])
                        sorted_indices = np.argsort(sig_values_parcel)[::-1]
                        top_indices = sorted_indices[: int(np.round(len(sorted_indices) * top_fraction))]

                        beta_values_same = utils.load_betas(subject_name, exp_name, held_out_label)
                        for condition_index, condition_name in enumerate(condition_names):
                            beta_values_condition = beta_values_same[:, :, :, condition_index]
                            beta_values_parcel = np.squeeze(beta_values_condition[parcel_index])
                            rows.append(
                                {
                                    "subject": subject_name,
                                    "definer": definer_name,
                                    "measurer": definer_name,
                                    "contrast": condition_name,
                                    "betas": np.mean(beta_values_parcel[top_indices]),
                                    "hemi": hemisphere_name,
                                    "parcel": roi_name,
                                }
                            )

                        beta_values_other = utils.load_betas(subject_name, alt_exp_name, held_out_label)
                        for condition_index, condition_name in enumerate(alt_condition_names):
                            beta_values_condition = beta_values_other[:, :, :, condition_index]
                            beta_values_parcel = np.squeeze(beta_values_condition[parcel_index])
                            rows.append(
                                {
                                    "subject": subject_name,
                                    "definer": definer_name,
                                    "measurer": other_name,
                                    "contrast": condition_name,
                                    "betas": np.mean(beta_values_parcel[top_indices]),
                                    "hemi": hemisphere_name,
                                    "parcel": roi_name,
                                }
                            )

    return pd.DataFrame(rows)


if __name__ == "__main__":
    dataframe_results = main()
