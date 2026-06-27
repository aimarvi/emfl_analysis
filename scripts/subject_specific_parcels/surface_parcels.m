% move native-space parcels onto the cortical surface.
% run volume_parcels.m first.

function surface_parcels(subjname)

paths = emfl_paths();
SUBJECTS_DIR = paths.recons_dir;
setenv('SUBJECTS_DIR', SUBJECTS_DIR);

srcParcelDir = paths.parcels_dir;
hemis = {'lh', 'rh'};

dJP = dir(fullfile(srcParcelDir, 'julian', '*.nii.gz'));
dLang = dir(fullfile(srcParcelDir, 'language', '*.nii.gz'));
dSpeech = dir(fullfile(srcParcelDir, 'speech', '*.nii.gz'));
dToM = dir(fullfile(srcParcelDir, 'tom', '*.nii.gz'));
dVWFA = dir(fullfile(srcParcelDir, 'vwfa', '*.nii.gz'));
dMD = dir(fullfile(srcParcelDir, 'md', '*.nii.gz'));

fprintf('subject: %s\n', subjname);

logDir = fullfile(paths.data_analysis_dir, 'masks', 'surf', subjname, 'log');
mkdir(logDir);
diary(fullfile(logDir, ['parcelize_' subjname '.txt']));

%% julian parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'surf', subjname, 'julian');
mkdir(outdir);
tform_dir = fullfile(paths.data_analysis_dir, 'subj2cvs_tform', subjname, 'final_CVSmorph_tocvs_avg35.m3z');

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

    cmd = ['mri_vol2surf --regheader ' subjname ...
        ' --hemi ' pnames{1} ...
        ' --mov ' anatParcelName ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% vwfa parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'surf', subjname, 'vwfa');
mkdir(outdir);
tform_dir = fullfile(paths.data_analysis_dir, 'subj2cvsmni152_tform', subjname, 'final_CVSmorph_tocvs_avg35_inMNI152.m3z');

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

    cmd = ['mri_vol2surf --regheader ' subjname ...
        ' --hemi ' pnames{1} ...
        ' --mov ' anatParcelName ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% md parcels
outdir = fullfile(paths.data_analysis_dir, 'masks', 'surf', subjname, 'md');
mkdir(outdir);

for did = 1:length(dMD)
    parcel = dMD(did).name;
    pnames = split(parcel, '.');

    if strcmp(pnames{1}, 'all')
        continue
    end

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

    cmd = ['mri_vol2surf --regheader ' subjname ...
        ' --hemi ' pnames{1} ...
        ' --mov ' anatParcelName ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% language parcels
voldir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'language');
outdir = fullfile(paths.data_analysis_dir, 'masks', 'surf', subjname, 'language');
mkdir(outdir);

for did = 1:length(dLang)
    parcel = dLang(did).name;
    pnames = split(parcel, '.');

    if strcmp(pnames{1}, 'all')
        continue
    end

    funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);

    cmd = ['mri_vol2surf --regheader ' subjname ...
        ' --hemi ' pnames{1} ...
        ' --mov ' fullfile(voldir, parcel) ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% tom parcels
voldir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'tom');
outdir = fullfile(paths.data_analysis_dir, 'masks', 'surf', subjname, 'tom');
mkdir(outdir);

for did = 1:length(dToM)
    parcel = dToM(did).name;
    pnames = split(parcel, '.');

    if contains(pnames{1}, 'h')
        funcParcelName = fullfile(outdir, [pnames{1} '.' pnames{2} '.func.nii.gz']);
        cmd = ['mri_vol2surf --regheader ' subjname ...
            ' --hemi ' pnames{1} ...
            ' --mov ' fullfile(voldir, parcel) ...
            ' --surf-fwhm 1 --o ' funcParcelName];
        unix(cmd);
    else
        for hid = 1:length(hemis)
            hemi = hemis{hid};
            funcParcelName = fullfile(outdir, [hemi '.' pnames{2} '.func.nii.gz']);
            cmd = ['mri_vol2surf --regheader ' subjname ...
                ' --hemi ' hemi ...
                ' --mov ' fullfile(voldir, parcel) ...
                ' --surf-fwhm 1 --o ' funcParcelName];
            unix(cmd);
        end
    end
end

%% speech parcels
voldir = fullfile(paths.data_analysis_dir, 'masks', 'vols', subjname, 'speech');
outdir = fullfile(paths.data_analysis_dir, 'masks', 'surf', subjname, 'speech');
mkdir(outdir);

for did = 1:length(dSpeech)
    parcel = dSpeech(did).name;
    pnames = split(parcel, '.');

    for hid = 1:length(hemis)
        hemi = hemis{hid};
        funcParcelName = fullfile(outdir, [hemi '.' pnames{2} '.func.nii.gz']);
        cmd = ['mri_vol2surf --regheader ' subjname ...
            ' --hemi ' hemi ...
            ' --mov ' fullfile(voldir, parcel) ...
            ' --surf-fwhm 1 --o ' funcParcelName];
        unix(cmd);
    end
end

diary off

end
