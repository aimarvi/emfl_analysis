from pathlib import Path

import nibabel as nib
import numpy as np

from emfl_paths import get_python_analysis_paths


PARCELLATION_DIR_NAMES = {
    "julian": "julian",
    "julian_parcels": "julian",
    "language": "language",
    "lang_parcels": "language",
    "speech": "speech",
    "speech_parcels_v2": "speech",
    "tom": "tom",
    "ToM_parcels": "tom",
    "vwfa": "vwfa",
    "vwfa_parcels": "vwfa",
    "md": "md",
    "md_parcels": "md",
}


def nifti_from_path(filepath_data):
    """
    Load a nifti-like file and return its data as a numpy array.

    Args:
        filepath_data (str | Path):
            Path to a nifti, mgz, or similar image file.

    Returns:
        np.ndarray:
            data_array (np.ndarray):
                Image data loaded into memory.
    """

    return np.array(nib.load(str(filepath_data)).dataobj)


def load_sigs(subj, exp, contrast, split):
    """
    Load significance values for one contrast.

    Args:
        subj (str):
            Subject identifier.
        exp (str):
            Localizer name.
        contrast (str):
            Contrast name.
        split (str):
            Run split label such as ``all``, ``even``, or ``odd``.

    Returns:
        np.ndarray:
            sig_values (np.ndarray):
                Voxelwise significance values.
    """

    paths = get_python_analysis_paths()
    subj_name = f"{subj}b" if exp == "ebavwfa" else subj
    filepath_sig = (
        paths["dir_project"]
        / f"vols_{exp}"
        / subj_name
        / "bold"
        / f"{exp}.sm3.{split}"
        / contrast
        / "sig.nii.gz"
    )
    return nifti_from_path(filepath_sig)


def load_betas(subj, exp, split):
    """
    Load all beta values for one localizer split.

    Args:
        subj (str):
            Subject identifier.
        exp (str):
            Localizer name.
        split (str):
            Run split label such as ``all``, ``even``, or ``odd``.

    Returns:
        np.ndarray:
            beta_values (np.ndarray):
                Voxelwise beta values with condition dimension last.
    """

    paths = get_python_analysis_paths()
    subj_name = f"{subj}b" if exp == "ebavwfa" else subj
    filepath_beta = (
        paths["dir_project"]
        / f"vols_{exp}"
        / subj_name
        / "bold"
        / f"{exp}.sm3.{split}"
        / "beta.nii.gz"
    )
    return nifti_from_path(filepath_beta)


def load_parcel(subj, parcellation, roi, hemi):
    """
    Load one subject-space parcel mask.

    Args:
        subj (str):
            Subject identifier.
        parcellation (str):
            Parcel family name.
        roi (str):
            Region-of-interest name.
        hemi (str):
            Hemisphere label, usually ``lh`` or ``rh``.

    Returns:
        np.ndarray:
            parcel_mask (np.ndarray):
                Parcel mask in subject native functional space.
    """

    if parcellation == "fs_dkt":
        paths = get_python_analysis_paths()
        filepath_atlas = paths["dir_recons"] / subj / "mri" / "FSatlas_functional.nii.gz"
        return nifti_from_path(filepath_atlas)

    if parcellation in {"md", "md_parcels"}:
        return load_md_macroparcel(subj=subj, roi=roi, hemi=hemi)

    dir_parcellation = resolve_parcellation_dir(subj=subj, parcellation=parcellation)
    filepaths_candidate = get_parcel_candidates(
        dir_parcellation=dir_parcellation,
        parcellation=parcellation,
        roi=roi,
        hemi=hemi,
    )
    filepath_parcel = resolve_existing_candidate(filepaths_candidate=filepaths_candidate)
    return nifti_from_path(filepath_parcel)


def load_md_macroparcel(subj, roi, hemi):
    """
    Build a macroparcel by summing matching MD subparcels.

    Args:
        subj (str):
            Subject identifier.
        roi (str):
            Macroparcel name such as ``frontal`` or ``parietal``.
        hemi (str):
            Hemisphere label.

    Returns:
        np.ndarray:
            macroparcel_mask (np.ndarray):
                Summed MD macroparcel mask.
    """

    dir_md = resolve_parcellation_dir(subj=subj, parcellation="md")
    filepaths_subparcels = sorted(filepath for filepath in dir_md.iterdir() if filepath.is_file())
    filepaths_subparcels = [filepath for filepath in filepaths_subparcels if "func" in filepath.name]

    hemi_prefix = hemi[0].lower()
    roi_label = roi.lower()

    if roi_label == "frontal":
        filepaths_group = [
            filepath
            for filepath in filepaths_subparcels
            if filepath.name.startswith(f"{hemi_prefix}.") and "Frontal" in filepath.name
        ]
    elif roi_label == "parietal":
        filepaths_group = [
            filepath
            for filepath in filepaths_subparcels
            if filepath.name.startswith(f"{hemi_prefix}.") and "Parietal" in filepath.name
        ]
    else:
        raise ValueError(f"unsupported md macroparcel roi: {roi}")

    if not filepaths_group:
        raise FileNotFoundError(f"no md subparcels found for {subj=} {roi=} {hemi=}")

    macroparcel_mask = None
    for filepath_subparcel in filepaths_group:
        subparcel_mask = nifti_from_path(filepath_subparcel)
        if macroparcel_mask is None:
            macroparcel_mask = np.zeros_like(subparcel_mask)
        macroparcel_mask = macroparcel_mask + subparcel_mask

    return macroparcel_mask


def resolve_parcellation_dir(subj, parcellation):
    """
    Resolve a subject-specific parcel directory.

    Args:
        subj (str):
            Subject identifier.
        parcellation (str):
            Parcel family name.

    Returns:
        Path:
            dir_parcellation (Path):
                Directory containing parcel files.
    """

    paths = get_python_analysis_paths()
    dir_name = PARCELLATION_DIR_NAMES.get(parcellation, parcellation)
    dir_parcellation = paths["dir_data_analysis"] / "masks" / "vols" / subj / dir_name
    if dir_parcellation.exists():
        return dir_parcellation

    legacy_dir = paths["dir_data_analysis"] / "masks" / "vols" / subj / parcellation
    if legacy_dir.exists():
        return legacy_dir

    return dir_parcellation


def get_parcel_candidates(dir_parcellation, parcellation, roi, hemi):
    """
    Return supported parcel filename candidates for one roi.

    Args:
        dir_parcellation (Path):
            Directory containing parcel files.
        parcellation (str):
            Parcel family name.
        roi (str):
            Region-of-interest name.
        hemi (str):
            Hemisphere label.

    Returns:
        list[Path]:
            filepaths_candidate (list[Path]):
                Candidate parcel file paths in preferred order.
    """

    hemi_prefix = hemi[0].lower()
    normalized_parcellation = PARCELLATION_DIR_NAMES.get(parcellation, parcellation)

    if normalized_parcellation == "julian":
        filenames = [
            f"{hemi}.{roi}.func.nii.gz",
            f"{hemi_prefix}{roi}_functional.nii.gz",
        ]
    elif normalized_parcellation == "language":
        filenames = [
            f"{hemi}.{roi}.func.nii.gz",
            f"{roi}.nii",
            f"{roi}.nii.gz",
        ]
    elif normalized_parcellation == "tom":
        filenames = [
            f"{hemi}.{roi}.func.nii.gz",
            f"{roi}.func.nii.gz",
            f"{roi}_xyz.nii.gz",
        ]
    elif normalized_parcellation == "vwfa":
        filenames = [
            f"lh.{roi}.func.nii.gz",
            f"l{roi}_functional.nii.gz",
        ]
    elif normalized_parcellation == "speech":
        filenames = [
            f"{hemi}.{roi}.func.nii.gz",
            "lang_speech_LH_1_5_mirrored_conjunction_final.nii",
            "lang_speech_LH_1_5_mirrored_conjunction_final.nii.gz",
        ]
    else:
        filenames = [f"{hemi}.{roi}.func.nii.gz"]

    return [dir_parcellation / filename for filename in filenames]


def resolve_existing_candidate(filepaths_candidate):
    """
    Return the first existing path from a candidate list.

    Args:
        filepaths_candidate (list[Path]):
            Candidate file paths in priority order.

    Returns:
        Path:
            filepath_existing (Path):
                First path that exists on disk.

    Raises:
        FileNotFoundError:
            If none of the candidates exist.
    """

    for filepath_candidate in filepaths_candidate:
        if filepath_candidate.exists():
            return filepath_candidate

    filepath_lines = "\n".join(str(filepath_candidate) for filepath_candidate in filepaths_candidate)
    raise FileNotFoundError(f"parcel file not found. tried:\n{filepath_lines}")
