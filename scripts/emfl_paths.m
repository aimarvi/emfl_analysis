function paths = emfl_paths()
% shared project paths for the emfl analysis scripts.

scripts_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(scripts_dir);

paths.scripts_dir = scripts_dir;
paths.project_dir = project_dir;

paths.analysis_dir = fullfile(project_dir, 'analysis');
paths.parcels_dir = fullfile(project_dir, 'PARCELS');
paths.recons_dir = fullfile(project_dir, 'recons');

paths.paras_vis_dir = fullfile(project_dir, 'paras_vis');
paths.paras_aud_dir = fullfile(project_dir, 'paras_aud');
paths.paras_audHalf_dir = fullfile(project_dir, 'paras_audHalf');

paths.vols_vis_dir = fullfile(project_dir, 'vols_vis');
paths.vols_aud_dir = fullfile(project_dir, 'vols_aud');
paths.vols_audHalf_dir = fullfile(project_dir, 'vols_audHalf');

paths.data_analysis_dir = fullfile(project_dir, 'data_analysis');
paths.dicoms_dir = fullfile(project_dir, 'data', 'dicoms');
end
