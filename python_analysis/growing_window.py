import numpy as np
import pandas as pd
from tqdm import tqdm

import gen_utils as utils


def main():
    """
    Collect growing-window beta summaries across two localizers.

    Returns:
        dict[str, pd.DataFrame]:
            dataframes_by_roi (dict[str, pd.DataFrame]):
                One dataframe per roi.
    """

    subjects = ["kaneff01"] + [f"kaneff{subject_id:02d}" for subject_id in range(6, 25)]
    roi_names = ["FFA", "OFA", "STS", "PPA", "OPA", "RSC"]
    contrast_names = ["Fa-O", "Fa-O", "Fa-O", "S-O", "S-O", "S-O"]
    hemisphere_names = ["rh"]
    condition_names = ["Fa", "O", "Scr", "S"]

    dataframes_by_roi = {}

    for roi_index, roi_name in enumerate(roi_names):
        contrast_name = contrast_names[roi_index]
        rows = []

        for hemisphere_name in hemisphere_names:
            for subject_name in tqdm(subjects):
                parcel_mask = utils.load_parcel(
                    subj=subject_name,
                    parcellation="julian",
                    roi=roi_name,
                    hemi=hemisphere_name,
                )
                parcel_index = np.where(parcel_mask != 0)

                sig_values = utils.load_sigs(subject_name, "vis", contrast_name, "all")[parcel_index].squeeze()
                sorted_indices = np.argsort(sig_values)[::-1]

                beta_values_all = utils.load_betas(subject_name, "foss", "all")
                beta_values_condition = beta_values_all[
                    parcel_index[0], parcel_index[1], parcel_index[2], : len(condition_names)
                ]
                beta_values_condition = beta_values_condition[sorted_indices, :]

                num_voxels = beta_values_condition.shape[0]
                for percent_selected in range(1, 101):
                    num_selected = int(np.ceil(percent_selected / 100 * num_voxels))
                    for condition_index, condition_name in enumerate(condition_names):
                        rows.append(
                            {
                                "subject": subject_name,
                                "percent": percent_selected,
                                "condition": condition_name,
                                "beta": np.mean(beta_values_condition[:num_selected, condition_index]),
                            }
                        )

        dataframes_by_roi[roi_name] = pd.DataFrame(rows)

    return dataframes_by_roi


if __name__ == "__main__":
    roi_dataframes = main()
