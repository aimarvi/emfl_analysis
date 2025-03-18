function [] = make_L2_final(subj_id, run_ids, dicom_name, exp_name, num_conditions, ...
    block_length, contrast, TR)

% @samhutch, @amarvi 03/17/2025
% helper function to run FS-FAST analysis. called by block_analysis_final.m
% output is saved to /analysis folder
% 
% args:
%     subj_id (str): subject name (eg. kaneff01)
%     run_ids (int array): run numbers as listed in dicom.info
%     dicom_name (str): dir housing all .dcm files
%     exp_name (str): localizer name (eg. vis, aud, audHalf)
%     num_conditions (int): number of stimulus conditions including fixation (eg. 5+1=6 for EMFL visual)
%     block_length (int): length of block in localizer, in sec
%     contrast (struct): functional contrasts to be analyzed
%     TR (int): temporal resolution (IPS) of fMRI scan, in sec
% 
% returns:
%     none

%get project directory
cd ..
project_dir = pwd;
cd ./scripts

if exist([project_dir '/analysis/L2_' subj_id '.mat'])
    load([project_dir '/analysis/L2_' subj_id '.mat']);
end

L2.(exp_name).subj_id = subj_id;
L2.(exp_name).exp_name = exp_name;
L2.(exp_name).para_name = [exp_name '.para'];
L2.(exp_name).TR = TR;
L2.(exp_name).num_conditions = num_conditions - 1;
L2.(exp_name).block_length = block_length;
L2.(exp_name).run_ids = run_ids;
L2.(exp_name).project_dir = project_dir;
L2.(exp_name).analysis_dir = [L2.(exp_name).project_dir '/analysis/' subj_id];
L2.(exp_name).functional_dir = [L2.(exp_name).project_dir '/vols_' exp_name '/' subj_id];
L2.(exp_name).dicoms_dir = [L2.(exp_name).project_dir '/data/dicoms/' subj_id];
L2.(exp_name).paras_dir = [L2.(exp_name).project_dir '/paras_' exp_name '/'];
L2.(exp_name).dicom_name = dicom_name;
L2.(exp_name).contrasts = contrast;

save([project_dir '/analysis/L2_' subj_id '.mat'], 'L2');
unix(['mkdir ' L2.(exp_name).analysis_dir]);
unix(['cp startup.m ' L2.(exp_name).analysis_dir]);

end
