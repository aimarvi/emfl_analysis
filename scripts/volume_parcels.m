% requires first running parcel_transform_final.m
% 
% converts parcels from template space to native space
% 
% julian, vwfa, language, ToM, physics, MD parcels
% Last Edit: amarvi 04/17/2025
% 
% args: 
%     subjname (str): subject name
% 
% returns:
%     none


%%% this is all you need to change (hopefully) %%%
function volume_parcels(subjname)

SUBJECTS_DIR = '../recons/';
setenv('SUBJECTS_DIR',SUBJECTS_DIR);

srcParcelDir = './parcels/';

dJP = dir([srcParcelDir 'all/*.nii.gz']);
dLang = dir([srcParcelDir 'EvLab_lang_parcels/langparcel*.nii']);
dSpeech = dir([srcParcelDir 'speech_parcels/*.nii']);
dToM = dir([srcParcelDir 'ToM_parcels/*.nii.gz']);
dPhys = dir([srcParcelDir 'physics/*.nii.gz']);
dVWFA = dir([srcParcelDir 'lvwfa.nii.gz']);
dMD = dir([srcParcelDir 'md/*.nii.gz']);

fprintf('subject: %s\n', subjname);

logDir = [SUBJECTS_DIR '../data_analysis/masks/vols/' subjname '/log/']; mkdir(logDir);
diaryname = ['parcelize_' subjname '.txt'];
diary([logDir diaryname]);

%% julian parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/vols/' ...
    subjname '/julian_parcels/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '../data_analysis/subj2cvs_tform/' ...
    subjname '/final_CVSmorph_tocvs_avg35.m3z'];
meanfunc_dir = [SUBJECTS_DIR '../vols_vis/' subjname ...
    '/bold/vis.sm3.all/meanfunc.nii.gz'];

% Transform parcel from CVS volume to subject's anatomial volume
for did = 1:length(dJP)
    parcel = dJP(did).name;
    pname = strtok(parcel, '.');
    anatParcelName = [outdir pname '_anatomical.nii.gz'];
    funcParcelName = [outdir pname '_functional.nii.gz'];

    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir 'all/' parcel ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd);

    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2vol --regheader --mov ' anatParcelName ...
        ' --targ ' meanfunc_dir ' --o ' funcParcelName ' --nearest'];
    unix(cmd);
end

%% vwfa parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/vols/' ...
    subjname '/vwfa_parcels/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '../data_analysis/subj2cvsmni152_tform/' ...
    subjname '/final_CVSmorph_tocvs_avg35_inMNI152.m3z'];
meanfunc_dir = [SUBJECTS_DIR '../vols_aud/' subjname ...
        '/bold/aud.sm3.all/meanfunc.nii.gz'];

for did = 1:length(dVWFA)
    parcel = dVWFA(did).name;
    pname = strtok(parcel, '.');

    anatParcelName = [outdir pname '_anatomical.nii.gz'];
    funcParcelName = [outdir pname '_functional.nii.gz'];

    % Transform parcel from CVS-MNI152 volume to subject's anatomial volume
    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir parcel ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd)

    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2vol --regheader --mov ' anatParcelName ...
        ' --targ ' meanfunc_dir ' --o ' funcParcelName ' --nearest'];
    unix(cmd);
end

%% MD parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/vols/' ...
    subjname '/md_parcels/']; mkdir(outdir);

for did = 1:length(dMD)
    parcel = dMD(did).name;
    pname = strtok(parcel, '.');
    anatParcelName = [outdir pname '_anatomical.nii.gz'];
    funcParcelName = [outdir pname '_functional.nii.gz'];

    % Transform parcel from CVS-MNI152 volume to subject's anatomial volume
    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir 'md/' parcel ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd)

    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2vol --regheader --mov ' anatParcelName ...
        ' --targ ' meanfunc_dir ' --o ' funcParcelName ' --nearest'];
    unix(cmd);
end

%% language parcels
outdir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
    subjname '/lang_parcels/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '/../data_analysis/fsavg2subj_tform/' ...
    subjname '/mni152_to_func.lta'];
meanfunc_dir = [SUBJECTS_DIR '/../vols_aud/' subjname '/bold/aud.sm3.all/meanfunc.nii.gz'];

% convert the fsavg space parcel to subject space
for did = 1:length(dLang)
    parcel = dLang(did).name;
    cmd = ['mri_vol2vol --mov ' srcParcelDir 'EvLab_lang_parcels/' parcel ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' outdir parcel];
    unix(cmd);
end

% bilateral speech parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/vols/' ...
    subjname '/speech_parcels/']; mkdir(outdir);
for did = 1:length(dSpeech)
    parcel = dSpeech(did).name;
    cmd = ['mri_vol2vol --mov ' srcParcelDir 'speech_parcels/' parcel ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' outdir parcel];
    unix(cmd);
end

%% ToM parcels
outdir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
    subjname '/ToM_parcels/']; mkdir(outdir);

% use the transformation to bring the ToM parcels to subject functional space
% convert the fsavg space parcel to subject space
for did = 1:length(dToM)
    parcel = dToM(did).name;
    cmd = ['mri_vol2vol --mov ' srcParcelDir 'ToM_parcels/' parcel ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' outdir parcel];
    unix(cmd);
end

%% physics parcels
outdir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
    subjname filesep '/physics_parcels/']; mkdir(outdir);
meanfunc_dir = [SUBJECTS_DIR '/../vols_vis/' ...
    subjname filesep 'bold/vis.sm3.all/meanfunc.nii.gz'];
tform_dir = [SUBJECTS_DIR '/../data_analysis/fsavg2subj_tform/' ...
    subjname '/fsavg2func.lta'];

% use the transformation to bring the physics parcels to subject functional space
% convert the fsavg space parcel to subject space
for did = 1:length(dPhys)
    parcel = dPhys(did).name;
    cmd = ['mri_vol2vol --mov ' srcParcelDir 'physics/' parcel...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' outdir parcel];
    unix(cmd);
end

diary off

end
                                                                                                                          
