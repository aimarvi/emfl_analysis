import numpy as np
import pandas as pd
from tqdm import tqdm

from emfl_paths import get_python_analysis_paths
import gen_utils as utils


def main():
    """
    Compare EMFL responses against repeat visual-only runs.

    Returns:
        pd.DataFrame:
            results_df (pd.DataFrame):
                One row per subject, experiment, condition, hemisphere, and parcel.
    """

    paths = get_python_analysis_paths()
    paths["dir_final_data"].mkdir(exist_ok=True)

    subject_map = {
        "kaneff01": "kanderson05",
        "kaneff13": "kanderson04",
        "kaneff14": "kanderson01",
        "kaneff17": "kanderson02",
        "kaneff18": "kanderson03",
    }
    hemispheres = ["rh", "lh"]

    rois_visual = ["vwfa", "FFA", "STS", "PPA", "EBA", "OFA", "OPA", "RSC", "LOC"]
    contrasts_visual = ["W-O", "Fa-O", "Fa-O", "S-O", "B-O", "Fa-O", "S-O", "S-O", "O-Scr"]
    visual_conditions = ["Fa", "S", "B", "O", "W"]
    top_fraction = 0.1

    rows = []

    for roi_name in tqdm(rois_visual):
        contrast_name = contrasts_visual[rois_visual.index(roi_name)]

        for hemisphere_name in hemispheres:
            if roi_name == "vwfa" and hemisphere_name == "rh":
                continue

            parcellation_name = "vwfa" if roi_name == "vwfa" else "julian"

            for subject_emfl, subject_repeat in subject_map.items():
                parcel_mask = utils.load_parcel(
                    subj=subject_emfl,
                    parcellation=parcellation_name,
                    roi=roi_name,
                    hemi=hemisphere_name,
                )
                parcel_index = parcel_mask != 0

                sig_values = utils.load_sigs(subject_emfl, "vis", contrast_name, "last")
                sig_values_parcel = np.squeeze(sig_values[parcel_index])
                sorted_indices = np.argsort(sig_values_parcel)[::-1]
                top_indices = sorted_indices[: int(np.round(len(sorted_indices) * top_fraction))]

                beta_values_emfl = utils.load_betas(subject_emfl, "vis", "first")
                for condition_index, condition_name in enumerate(visual_conditions):
                    beta_values_condition = beta_values_emfl[:, :, :, condition_index]
                    beta_values_parcel = np.squeeze(beta_values_condition[parcel_index])
                    rows.append(
                        {
                            "subject": subject_emfl,
                            "experiment": "emfl",
                            "contrast": condition_name,
                            "betas": np.mean(beta_values_parcel[top_indices]),
                            "hemi": hemisphere_name,
                            "parcel": roi_name,
                        }
                    )

                beta_values_repeat = utils.load_betas(subject_repeat, "effloc", "all")
                for condition_index, condition_name in enumerate(visual_conditions):
                    beta_values_condition = beta_values_repeat[:, :, :, condition_index]
                    beta_values_parcel = np.squeeze(beta_values_condition[parcel_index])
                    rows.append(
                        {
                            "subject": subject_emfl,
                            "experiment": "vis",
                            "contrast": condition_name,
                            "betas": np.mean(beta_values_parcel[top_indices]),
                            "hemi": hemisphere_name,
                            "parcel": roi_name,
                        }
                    )

    dataframe_results = pd.DataFrame(rows)
    filepath_output = paths["dir_final_data"] / "uni_EMFL-select.pkl"
    dataframe_results.to_pickle(filepath_output)
    return dataframe_results


if __name__ == "__main__":
    dataframe_results = main()
