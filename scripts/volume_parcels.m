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

% path to your project directory (specifically the ./recons folder)
SUBJECTS_DIR = '/XXX/recons/';
setenv('SUBJECTS_DIR',SUBJECTS_DIR);

srcParcelDir = 'PARCELS/';

dJP = dir([srcParcelDir 'julian/*.nii.gz']);
dLang = dir([srcParcelDir 'language/.nii.gz']);
dSpeech = dir([srcParcelDir 'speech/*.nii.gz']);
dToM = dir([srcParcelDir 'tom/*.nii.gz']);
dVWFA = dir([srcParcelDir 'vwfa/*.nii.gz']);
dMD = dir([srcParcelDir 'md/*.nii.gz']);

fprintf('subject: %s\n', subjname);

logDir = [SUBJECTS_DIR '../data_analysis/masks/vols/' subjname '/log/']; mkdir(logDir);
diaryname = ['parcelize_' subjname '.txt'];
diary([logDir diaryname]);

%% julian parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/vols/' ...
    subjname '/julian/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '../data_analysis/subj2cvs_tform/' ...
    subjname '/final_CVSmorph_tocvs_avg35.m3z'];
meanfunc_dir = [SUBJECTS_DIR '../vols_vis/' subjname ...
    '/bold/vis.sm3.all/meanfunc.nii.gz'];

% Transform parcel from CVS volume to subject's anatomial volume
for did = 1:length(dJP)
    parcel = dJP(did).name;
    pnames = split(parcel, '.');

    anatParcelName = [outdir pnames(1) '.' pnames(2) '.anat.nii.gz'];
    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir 'julian/' parcel ...
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
    subjname '/vwfa/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '../data_analysis/subj2cvsmni152_tform/' ...
    subjname '/final_CVSmorph_tocvs_avg35_inMNI152.m3z'];
meanfunc_dir = [SUBJECTS_DIR '../vols_aud/' subjname ...
        '/bold/aud.sm3.all/meanfunc.nii.gz'];

for did = 1:length(dVWFA)
    parcel = dVWFA(did).name;
    pnames = split(parcel, '.');

    anatParcelName = [outdir pnames(1) '.' pnames(2) '.anat.nii.gz'];
    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

    % Transform parcel from CVS-MNI152 volume to subject's anatomial volume
    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir 'vwfa/' parcel ...
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
    subjname '/md/']; mkdir(outdir);

for did = 1:length(dMD)
    parcel = dMD(did).name;
    pnames = split(parcel, '.');

    anatParcelName = [outdir pnames(1) '.' pnames(2) '.anat.nii.gz'];
    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

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
    subjname '/language/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '/../data_analysis/fsavg2subj_tform/' ...
    subjname '/mni152_to_func.lta'];
meanfunc_dir = [SUBJECTS_DIR '/../vols_aud/' subjname '/bold/aud.sm3.all/meanfunc.nii.gz'];

% convert the fsavg space parcel to subject space
for did = 1:length(dLang)
    parcel = dLang(did).name;
    pnames = split(parcel, '.');

    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

    cmd = ['mri_vol2vol --mov ' srcParcelDir 'language/' parcel ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' outdir funcParcelName];
    unix(cmd);
end

% bilateral speech parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/vols/' ...
    subjname '/speech/']; mkdir(outdir);
for did = 1:length(dSpeech)
    parcel = dSpeech(did).name;
    pnames = split(parcel, '.');

    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

    cmd = ['mri_vol2vol --mov ' srcParcelDir 'speech/' parcel ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' outdir funcParcelName];
    unix(cmd);
end

%% ToM parcels
outdir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
    subjname '/tom/']; mkdir(outdir);

% use the transformation to bring the ToM parcels to subject functional space
% convert the fsavg space parcel to subject space
for did = 1:length(dToM)
    parcel = dToM(did).name;
    pnames = split(parcel, '.');

    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

    cmd = ['mri_vol2vol --mov ' srcParcelDir 'tom/' parcel ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' outdir funcParcelName];
    unix(cmd);
end

%% physics has not been configured yet
% %% physics parcels
% outdir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
%     subjname filesep '/physics/']; mkdir(outdir);
% meanfunc_dir = [SUBJECTS_DIR '/../vols_vis/' ...
%     subjname filesep 'bold/vis.sm3.all/meanfunc.nii.gz'];
% tform_dir = [SUBJECTS_DIR '/../data_analysis/fsavg2subj_tform/' ...
%     subjname '/fsavg2func.lta'];
% 
% % use the transformation to bring the physics parcels to subject functional space
% % convert the fsavg space parcel to subject space
% for did = 1:length(dPhys)
%     parcel = dPhys(did).name;
%     pnames = split(parcel, '.');
% 
%     funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];
% 
%     cmd = ['mri_vol2vol --mov ' srcParcelDir 'physics/' parcel...
%         ' --targ ' meanfunc_dir ...
%         ' --reg ' tform_dir ...
%         ' --o ' outdir funcParcelName];
%     unix(cmd);
% end

diary off

end
                                                                                                                          
