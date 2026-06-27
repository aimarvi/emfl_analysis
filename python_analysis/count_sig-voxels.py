import numpy as np
import pandas as pd

import gen_utils as utils


def main():
    """
    Count subjects with at least a threshold number of significant voxels.

    Returns:
        pd.DataFrame:
            results_df (pd.DataFrame):
                Summary dataframe across thresholds and run sets.
    """

    subjects = ["kaneff01"] + [f"kaneff{subject_id:02d}" for subject_id in range(6, 25)]
    run_sets = ["odd", "all"]
    thresholds = [3, 10]
    roi_names = ["RTPJ"]
    contrast_names = ["FB-FP"]
    hemisphere_names = ["rh"]

    rows = []

    for threshold_count in thresholds:
        for run_label in run_sets:
            for hemisphere_name in hemisphere_names:
                for roi_index, roi_name in enumerate(roi_names):
                    contrast_name = contrast_names[roi_index]
                    num_subjects_below_threshold = 0
                    num_sig_voxels = []
                    num_parcel_voxels = []

                    for subject_name in subjects:
                        parcel_mask = utils.load_parcel(
                            subj=subject_name,
                            parcellation="tom",
                            roi=roi_name,
                            hemi=hemisphere_name,
                        )
                        parcel_index = np.where(parcel_mask != 0)

                        sig_values = utils.load_sigs(subject_name, "audHalf", contrast_name, run_label)
                        sig_values = sig_values[parcel_index].squeeze()

                        count_sig_voxels = np.sum(sig_values > 3)
                        if count_sig_voxels < threshold_count:
                            num_subjects_below_threshold += 1

                        num_sig_voxels.append(count_sig_voxels)
                        num_parcel_voxels.append(np.sum(parcel_mask != 0))

                    rows.append(
                        {
                            "experiment": "audHalf",
                            "roi": roi_name,
                            "hemi": hemisphere_name,
                            "threshold": threshold_count,
                            "runs": run_label,
                            "count": len(subjects) - num_subjects_below_threshold,
                            "num-sigs": np.mean(np.array(num_sig_voxels)),
                            "psize": np.mean(np.array(num_parcel_voxels)),
                            "category": "efficient",
                        }
                    )

    return pd.DataFrame(rows)


if __name__ == "__main__":
    dataframe_results = main()
