from pathlib import Path


def get_python_analysis_paths():
    """
    Return shared repository paths for the python analysis scripts.

    Returns:
        dict:
            paths (dict):
                Repository-relative directories used across python_analysis.
    """

    dir_python_analysis = Path(__file__).resolve().parent
    dir_project = dir_python_analysis.parent

    return {
        "dir_python_analysis": dir_python_analysis,
        "dir_project": dir_project,
        "dir_recons": dir_project / "recons",
        "dir_data_analysis": dir_project / "data_analysis",
        "dir_final_data": dir_python_analysis / "final_data",
    }
