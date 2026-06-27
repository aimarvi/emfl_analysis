% convert template parcels into subject native functional volume space.
% run parcel_transform_final.m first.

function volume_parcels(subjname)

paths = emfl_paths();
SUBJECTS_DIR = paths.recons_dir;
setenv('SUBJECTS_DIR', SUBJECTS_DIR);

srcParcelDir = paths.parcels_dir;

dJP = dir(fullfile(srcParcelDir, 'julian', '*.nii.gz'));
dLang = dir(fullfile(srcParcelDir, 'language', '*.nii.gz'));
dSpeech = dir(fullfile(srcParcelDir, 'speech', '*.nii.gz'));
dToM = dir(fullfile(srcParcelDir, 'tom', '*.nii.gz'));
dVWFA = dir(fullfile(srcParcelDir, 'vwfa', '*.nii.gz'));
dMD = dir(fullfile(srcParcelDir, 'md', '*.nii.gz'));

fprintf('subject: %s\n', subjname);

logDir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'log');
mkdir(logDir);
diary(fullfile(logDir, ['parcelize_' subjname '.txt']));

%% julian parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'julian');
mkdir(outdir);
tform_dir = fullfile(paths.data_analysis_dir, 'subj2cvs_tform', subjname, 'final_CVSmorph_tocvs_avg35.m3z');
meanfunc_dir = fullfile(paths.vols_vis_dir, subjname, 'bold', 'vis.sm3.all', 'meanfunc.nii.gz');

for did = 1:length(dJP)
    parcel = dJP(did).name;
    pnames = split(parcel, '.');

    anatParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.anat.nii.gz']);
    funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);
    filepath_source = fullfile(srcParcelDir, 'julian', parcel);

    cmd = ['mri_vol2vol --noDefM3zPath' ...
        ' --mov ' fullfile(SUBJECTS_DIR, subjname, 'mri', 'orig.mgz') ...
        ' --targ ' filepath_source ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd);

    cmd = ['mri_vol2vol --regheader --mov ' anatParcelName ...
        ' --targ ' meanfunc_dir ...
        ' --o ' funcParcelName ...
        ' --nearest'];
    unix(cmd);
end

%% vwfa parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'vwfa');
mkdir(outdir);
tform_dir = fullfile(paths.data_analysis_dir, 'subj2cvsmni152_tform', subjname, 'final_CVSmorph_tocvs_avg35_inMNI152.m3z');
meanfunc_dir = fullfile(paths.vols_aud_dir, subjname, 'bold', 'aud.sm3.all', 'meanfunc.nii.gz');

for did = 1:length(dVWFA)
    parcel = dVWFA(did).name;
    pnames = split(parcel, '.');

    anatParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.anat.nii.gz']);
    funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);
    filepath_source = fullfile(srcParcelDir, 'vwfa', parcel);

    cmd = ['mri_vol2vol --noDefM3zPath' ...
        ' --mov ' fullfile(SUBJECTS_DIR, subjname, 'mri', 'orig.mgz') ...
        ' --targ ' filepath_source ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd);

    cmd = ['mri_vol2vol --regheader --mov ' anatParcelName ...
        ' --targ ' meanfunc_dir ...
        ' --o ' funcParcelName ...
        ' --nearest'];
    unix(cmd);
end

%% md parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'md');
mkdir(outdir);

for did = 1:length(dMD)
    parcel = dMD(did).name;
    pnames = split(parcel, '.');

    anatParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.anat.nii.gz']);
    funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);
    filepath_source = fullfile(srcParcelDir, 'md', parcel);

    cmd = ['mri_vol2vol --noDefM3zPath' ...
        ' --mov ' fullfile(SUBJECTS_DIR, subjname, 'mri', 'orig.mgz') ...
        ' --targ ' filepath_source ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd);

    cmd = ['mri_vol2vol --regheader --mov ' anatParcelName ...
        ' --targ ' meanfunc_dir ...
        ' --o ' funcParcelName ...
        ' --nearest'];
    unix(cmd);
end

%% language parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'language');
mkdir(outdir);
tform_dir = fullfile(paths.data_analysis_dir, 'fsavg2subj_tform', subjname, 'mni152_to_func.lta');
meanfunc_dir = fullfile(paths.vols_aud_dir, subjname, 'bold', 'aud.sm3.all', 'meanfunc.nii.gz');

for did = 1:length(dLang)
    parcel = dLang(did).name;
    pnames = split(parcel, '.');

    funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);
    filepath_source = fullfile(srcParcelDir, 'language', parcel);

    cmd = ['mri_vol2vol --mov ' filepath_source ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' funcParcelName];
    unix(cmd);
end

%% speech parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'speech');
mkdir(outdir);

for did = 1:length(dSpeech)
    parcel = dSpeech(did).name;
    pnames = split(parcel, '.');

    funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);
    filepath_source = fullfile(srcParcelDir, 'speech', parcel);

    cmd = ['mri_vol2vol --mov ' filepath_source ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' funcParcelName];
    unix(cmd);
end

%% tom parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'tom');
mkdir(outdir);

for did = 1:length(dToM)
    parcel = dToM(did).name;
    pnames = split(parcel, '.');

    funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);
    filepath_source = fullfile(srcParcelDir, 'tom', parcel);

    cmd = ['mri_vol2vol --mov ' filepath_source ...
        ' --targ ' meanfunc_dir ...
        ' --reg ' tform_dir ...
        ' --o ' funcParcelName];
    unix(cmd);
end

%% physics parcels
% leave this commented because the workflow is incomplete.
% outdir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'physics');
% mkdir(outdir);
% meanfunc_dir = fullfile(paths.vols_vis_dir, subjname, 'bold', 'vis.sm3.all', 'meanfunc.nii.gz');
% tform_dir = fullfile(paths.data_analysis_dir, 'fsavg2subj_tform', subjname, 'fsavg2func.lta');
% dPhys = dir(fullfile(srcParcelDir, 'physics', '*.nii.gz'));
%
% for did = 1:length(dPhys)
%     parcel = dPhys(did).name;
%     pnames = split(parcel, '.');
%     funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);
%     filepath_source = fullfile(srcParcelDir, 'physics', parcel);
%
%     cmd = ['mri_vol2vol --mov ' filepath_source ...
%         ' --targ ' meanfunc_dir ...
%         ' --reg ' tform_dir ...
%         ' --o ' funcParcelName];
%     unix(cmd);
% end

diary off

end
