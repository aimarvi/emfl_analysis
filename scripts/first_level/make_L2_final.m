function [] = make_L2_final(subj_id, run_ids, dicom_name, exp_name, num_conditions, ...
    block_length, contrast, TR)

% build and save the per-subject l2 structure used by fs-fast.
% write the metadata needed by downstream analysis steps.

paths = emfl_paths();
project_dir = paths.project_dir;

filepath_l2 = fullfile(paths.analysis_dir, ['L2_' subj_id '.mat']);
if exist(filepath_l2, 'file')
    load(filepath_l2);
end

L2.(exp_name).subj_id = subj_id;
L2.(exp_name).exp_name = exp_name;
L2.(exp_name).para_name = [exp_name '.para'];
L2.(exp_name).TR = TR;
L2.(exp_name).num_conditions = num_conditions - 1;
L2.(exp_name).block_length = block_length;
L2.(exp_name).run_ids = run_ids;
L2.(exp_name).project_dir = project_dir;
L2.(exp_name).analysis_dir = fullfile(L2.(exp_name).project_dir, 'analysis', subj_id);
L2.(exp_name).functional_dir = fullfile(L2.(exp_name).project_dir, ['vols_' exp_name], subj_id);
L2.(exp_name).dicoms_dir = fullfile(paths.dicoms_dir, subj_id);
L2.(exp_name).paras_dir = fullfile(L2.(exp_name).project_dir, ['paras_' exp_name]);
L2.(exp_name).dicom_name = dicom_name;
L2.(exp_name).contrasts = contrast;

save(filepath_l2, 'L2');
mkdir(L2.(exp_name).analysis_dir);
copyfile(fullfile(paths.scripts_dir, 'startup.m'), L2.(exp_name).analysis_dir);

end
