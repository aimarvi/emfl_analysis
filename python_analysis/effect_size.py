import numpy as np
import pandas as pd
from tqdm import tqdm

import gen_utils as utils


def main():
    """
    Collect held-out beta values from top parcel voxels.

    Returns:
        pd.DataFrame:
            results_df (pd.DataFrame):
                One row per subject, condition, hemisphere, and parcel.
    """

    visual_conditions = ["Fa", "S", "B", "O", "W"]
    auditory_conditions = ["FB", "FP", "NW", "QLT", "MATH"]

    subjects = ["kaneff01"] + [f"kaneff{subject_id:02d}" for subject_id in range(6, 25)]
    hemispheres = ["rh", "lh"]
    run_sets = ["even", "odd"]

    rois_visual = ["vwfa", "FFA", "STS", "PPA", "EBA", "OFA", "OPA", "RSC", "LOC"]
    contrasts_visual = ["W-O", "Fa-O", "Fa-O", "S-O", "B-O", "Fa-O", "S-O", "S-O", "O-Scr"]

    top_fraction = 0.1
    rows = []

    for roi_name in tqdm(rois_visual):
        contrast_name = contrasts_visual[rois_visual.index(roi_name)]

        for hemisphere_name in hemispheres:
            if roi_name == "vwfa" and hemisphere_name == "rh":
                continue

            parcellation_name = "vwfa" if roi_name == "vwfa" else "julian"

            for subject_name in subjects:
                parcel_mask = utils.load_parcel(
                    subj=subject_name,
                    parcellation=parcellation_name,
                    roi=roi_name,
                    hemi=hemisphere_name,
                )
                parcel_index = parcel_mask != 0

                for run_label in run_sets:
                    held_out_label = "odd" if run_label == "even" else "even"
                    sig_values = utils.load_sigs(subject_name, "vis", contrast_name, run_label)
                    sig_values_parcel = np.squeeze(sig_values[parcel_index])
                    sorted_indices = np.argsort(sig_values_parcel)[::-1]
                    top_indices = sorted_indices[: int(np.round(len(sorted_indices) * top_fraction))]

                    beta_values_visual = utils.load_betas(subject_name, "vis", held_out_label)
                    for condition_index, condition_name in enumerate(visual_conditions):
                        beta_values_condition = beta_values_visual[:, :, :, condition_index]
                        beta_values_parcel = np.squeeze(beta_values_condition[parcel_index])
                        rows.append(
                            {
                                "subject": subject_name,
                                "contrast": condition_name,
                                "betas": np.mean(beta_values_parcel[top_indices]),
                                "hemi": hemisphere_name,
                                "parcel": roi_name,
                            }
                        )

                    beta_values_auditory = utils.load_betas(subject_name, "aud", held_out_label)
                    for condition_index, condition_name in enumerate(auditory_conditions):
                        beta_values_condition = beta_values_auditory[:, :, :, condition_index]
                        beta_values_parcel = np.squeeze(beta_values_condition[parcel_index])
                        rows.append(
                            {
                                "subject": subject_name,
                                "contrast": condition_name,
                                "betas": np.mean(beta_values_parcel[top_indices]),
                                "hemi": hemisphere_name,
                                "parcel": roi_name,
                            }
                        )

    return pd.DataFrame(rows)


if __name__ == "__main__":
    dataframe_results = main()
