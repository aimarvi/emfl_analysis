function paths = emfl_matlab_paths()
% shared project paths for matlab analysis scripts.

dir_matlab_analysis = fileparts(mfilename('fullpath'));
dir_project = fileparts(dir_matlab_analysis);

paths.dir_matlab_analysis = dir_matlab_analysis;
paths.dir_project = dir_project;
paths.dir_recons = fullfile(dir_project, 'recons');
paths.dir_data_analysis = fullfile(dir_project, 'data_analysis');
end
