function [] = block_analysis_final(subj_id, exp_name, unpackFlag, preprocFlag, makeAnalysisFlag, ...
    runAnalysisFlag, glmSingleFlag, volumeFlag, surfaceFlag, smoothing, para_stem, para_ext)
%% fmri block design analysis
% main fs-fast workflow for one subject and one localizer.
% called by prep_analysis_final().

%% setup

paths = emfl_paths();
filepath_l2 = fullfile(paths.analysis_dir, ['L2_' subj_id '.mat']);
load(filepath_l2, 'L2');
fprintf('L2 structure loaded successfully.\n');

mkdir(fullfile(L2.(exp_name).functional_dir, 'bold'));
write_subject_name_file(subj_id, L2.(exp_name).functional_dir);

%% unpack dicoms

if unpackFlag
    sourcefolder = fullfile(L2.(exp_name).dicoms_dir, L2.(exp_name).dicom_name);
    targetfolder = fullfile(L2.(exp_name).project_dir, ['vols_' exp_name], subj_id);
    run_ids = L2.(exp_name).run_ids;

    fprintf('Unpacking functional runs for %s.\n', exp_name);
    for runid = 1:length(run_ids)
        cmd = ['unpacksdcmdir -src ' sourcefolder ...
            ' -targ ' targetfolder ...
            ' -run ' num2str(run_ids(runid)) ...
            ' bold nii f.nii.gz'];
        fprintf('Executing: %s\n', cmd);
        unix(cmd);
    end

    fprintf('unpack finished.\n');
    pause(1);
end

%% preprocessing

if preprocFlag
    fprintf('\nPreprocessing data.\n\n');
    unix(['preproc-sess -s ' subj_id ...
        ' -d ' fullfile(L2.(exp_name).functional_dir, '..') ...
        ' -per-run' ...
        ' -fsd bold -fwhm ' smoothing ...
        ' -force']);

    fprintf('\nTransforming data to anatomical space.\n\n');
    if isempty(smoothing)
        smoothing = '0';
    end

    for r = 1:length(L2.(exp_name).run_ids)
        run_dir = fullfile(L2.(exp_name).functional_dir, 'bold', sprintf('%03d', L2.(exp_name).run_ids(r)));
        cmd = ['mri_vol2vol --reg ' fullfile(run_dir, 'register.dof6.lta') ...
            ' --mov ' fullfile(run_dir, ['fmcpr.sm' smoothing '.nii.gz']) ...
            ' --fstarg' ...
            ' --no-resample' ...
            ' --o ' fullfile(run_dir, ['fmcpr_reg.sm' smoothing '.nii.gz'])];
        unix(cmd);
    end
else
    fprintf('\nSkipping preprocessing.\n\n');
end

%% copy para files and create run lists

copy_para_files(L2.(exp_name), subj_id, exp_name, para_stem, para_ext);
create_runlist_files(L2.(exp_name), exp_name, 'odd_even');

%% build analysis plans

if makeAnalysisFlag
    if volumeFlag
        splits = {'all', 'even', 'odd'};
        for s = 1:length(splits)
            split = splits{s};
            analysisname = [exp_name '.sm' smoothing '.' split];

            unix(['mkanalysis-sess -a ' fullfile(L2.(exp_name).analysis_dir, analysisname) ...
                ' -native' ...
                ' -funcstem fmcpr_reg.sm' smoothing ...
                ' -fsd bold' ...
                ' -event-related' ...
                ' -paradigm ' L2.(exp_name).para_name ...
                ' -nconditions ' num2str(L2.(exp_name).num_conditions) ...
                ' -refeventdur ' num2str(L2.(exp_name).block_length) ...
                ' -nuisreg mcprextreg 6' ...
                ' -force' ...
                ' -TR ' num2str(L2.(exp_name).TR) ...
                ' -polyfit 1' ...
                ' -spmhrf 0' ...
                ' -runlistfile ' exp_name '_' split '.rlf']);

            create_contrast_files(L2.(exp_name), analysisname);
        end
    end

    if surfaceFlag
        splits = {'all', 'even', 'odd'};
        hemis = {'rh', 'lh'};
        for h = 1:length(hemis)
            hemi = hemis{h};
            for s = 1:length(splits)
                split = splits{s};
                analysisname = [exp_name '.sm' smoothing '.' split '.' hemi];

                unix(['mkanalysis-sess -a ' fullfile(L2.(exp_name).analysis_dir, analysisname) ...
                    ' -surface self ' hemi ...
                    ' -fsd bold -fwhm ' smoothing ...
                    ' -event-related' ...
                    ' -force' ...
                    ' -paradigm ' L2.(exp_name).para_name ...
                    ' -nconditions ' num2str(L2.(exp_name).num_conditions) ...
                    ' -refeventdur ' num2str(L2.(exp_name).block_length) ...
                    ' -TR ' num2str(L2.(exp_name).TR) ...
                    ' -polyfit 1' ...
                    ' -spmhrf 0' ...
                    ' -mcextreg' ...
                    ' -runlistfile ' exp_name '_' split '.rlf' ...
                    ' -per-session']);

                create_contrast_files(L2.(exp_name), analysisname);
            end
        end
    end
end

%% run the analyses

if runAnalysisFlag
    if volumeFlag
        workingDir = pwd;
        cd(L2.(exp_name).analysis_dir);
        splits = {'all', 'even', 'odd'};
        for s = 1:length(splits)
            split = splits{s};
            analysisname = [exp_name '.sm' smoothing '.' split];
            unix(['selxavg3-sess -s ' subj_id ...
                ' -d ' fullfile(L2.(exp_name).functional_dir, '..') ...
                ' -analysis ' analysisname ...
                ' -no-preproc -overwrite']);
        end
        cd(workingDir);
    end

    if surfaceFlag
        workingDir = pwd;
        cd(L2.(exp_name).analysis_dir);
        splits = {'all', 'even', 'odd'};
        hemis = {'rh', 'lh'};
        for h = 1:length(hemis)
            hemi = hemis{h};
            for s = 1:length(splits)
                split = splits{s};
                analysisname = [exp_name '.sm' smoothing '.' split '.' hemi];
                unix(['selxavg3-sess -s ' subj_id ...
                    ' -d ' fullfile(L2.(exp_name).functional_dir, '..') ...
                    ' -analysis ' analysisname ...
                    ' -overwrite']);
            end
        end
        cd(workingDir);
    end
end

%% glmsingle

if glmSingleFlag
    glmSingleDir = getenv('GLMSINGLE_DIR');
    if isempty(glmSingleDir)
        error('Set GLMSINGLE_DIR before enabling glmSingleFlag.');
    end
    addpath(genpath(glmSingleDir));

    if volumeFlag
        fprintf('Processing volume data with GLMsingle.\n');

        file_name = ['fmcpr.sm' smoothing '.nii.gz'];
        runs = L2.(exp_name).run_ids;
        run_data = cell(1, length(runs));
        design = cell(1, length(runs));

        for r = 1:length(runs)
            run_dir = fullfile(L2.(exp_name).functional_dir, 'bold', sprintf('%03d', runs(r)));

            file = fullfile(run_dir, file_name);
            data = MRIread(file);
            data = squeeze(data.vol);
            run_data{r} = single(data);

            para_name = fullfile(run_dir, [exp_name '.para']);
            vars = read_parafile(para_name);
            design{r} = get_design(vars, size(run_data{r}, 4), L2.(exp_name).num_conditions, L2.(exp_name).TR);
        end

        fprintf('Running GLMsingle on all runs.\n');

        output_dir = fullfile(L2.(exp_name).functional_dir, 'bold', 'GLMsingle_results');
        mkdir(output_dir);
        stimdur = L2.(exp_name).block_length;
        tr = L2.(exp_name).TR;

        [~,~,convmat,cache] = GLMestimatesingletrial(design, run_data, stimdur, tr, output_dir);

        save(fullfile(output_dir, 'convmat.mat'), 'convmat', '-v7.3');
        save(fullfile(output_dir, 'cache.mat'), 'cache', '-v7.3');

        modelD = load(fullfile(output_dir, 'TYPED_FITHRF_GLMDENOISE_RR.mat'));
        betasD = modelD.modelmd;

        modelC = load(fullfile(output_dir, 'TYPEC_FITHRF_GLMDENOISE.mat'));
        betasC = modelC.modelmd;

        save(fullfile(output_dir, 'betas_trialsD.mat'), 'betasD', '-v7.3');
        save(fullfile(output_dir, 'betas_trialsC.mat'), 'betasC', '-v7.3');

        % reorder the betas by condition.
        design_concat = cat(1, design{:});
        cond_order = [];
        for p = 1:size(design_concat, 1)
            if any(design_concat(p, :))
                cond_order = [cond_order find(design_concat(p, :))];
            end
        end

        x = size(betasD, 1);
        y = size(betasD, 2);
        z = size(betasD, 3);
        num_conditions = size(design{1}, 2);
        num_trials = size(betasD, 4) / num_conditions;

        new_betasD = nan(x, y, z, num_trials, num_conditions);
        new_betasC = nan(x, y, z, num_trials, num_conditions);

        for c = 1:L2.(exp_name).num_conditions
            fprintf('Condition %i was repeated %i times.\n', c, length(find(cond_order == c)));
            indices = find(cond_order == c);

            cond_betasD = betasD(:,:,:,indices);
            new_betasD(:,:,:,:,c) = cond_betasD;

            cond_betasC = betasC(:,:,:,indices);
            new_betasC(:,:,:,:,c) = cond_betasC;
        end

        save(fullfile(output_dir, 'betas_conditionsD.mat'), 'new_betasD', '-v7.3');
        save(fullfile(output_dir, 'betas_conditionsC.mat'), 'new_betasC', '-v7.3');
    end
end

end

function write_subject_name_file(subj_id, functional_dir)
filepath_subjectname = fullfile(functional_dir, 'subjectname');
fid = fopen(filepath_subjectname, 'w');
fprintf(fid, '%s\n', subj_id);
fclose(fid);
end

function copy_para_files(L2_exp, subj_id, exp_name, para_stem, para_ext)
fprintf('Copying para files.\n');
for r = 1:length(L2_exp.run_ids)
    filepath_source = fullfile(L2_exp.paras_dir, subj_id, [para_stem num2str(r) para_ext]);
    filepath_target = fullfile(L2_exp.functional_dir, 'bold', sprintf('%03d', L2_exp.run_ids(r)), [exp_name '.para']);
    unix(['rsync -av ' filepath_source ' ' filepath_target]);
end
end

function create_runlist_files(L2_exp, exp_name, split_mode)
fprintf('Creating run list files.\n');
unix(['rm -f ' fullfile(L2_exp.functional_dir, 'bold', '*.rlf')]);

for r = 1:length(L2_exp.run_ids)
    run_label = sprintf('%03d', L2_exp.run_ids(r));
    filepath_all = fullfile(L2_exp.functional_dir, 'bold', [exp_name '_all.rlf']);
    append_run_label(filepath_all, run_label);

    if strcmp(split_mode, 'odd_even')
        if rem(r, 2) == 0
            filepath_split = fullfile(L2_exp.functional_dir, 'bold', [exp_name '_even.rlf']);
        else
            filepath_split = fullfile(L2_exp.functional_dir, 'bold', [exp_name '_odd.rlf']);
        end
    else
        error('Unknown split mode: %s', split_mode);
    end

    append_run_label(filepath_split, run_label);
end
end

function append_run_label(filepath_rlf, run_label)
fid = fopen(filepath_rlf, 'a');
fprintf(fid, '%s\n', run_label);
fclose(fid);
end

function create_contrast_files(L2_exp, analysisname)
for contrastid = 1:length(L2_exp.contrasts.names)
    contraststring = [' -contrast ' L2_exp.contrasts.names{contrastid}];
    lids = L2_exp.contrasts.cidleft{contrastid};
    rids = L2_exp.contrasts.cidright{contrastid};

    % write left-side contrast terms first.
    for leftcids = 1:length(lids)
        contraststring = [contraststring ' -a ' num2str(lids(leftcids))];
    end

    for rightcids = 1:length(rids)
        contraststring = [contraststring ' -c ' num2str(rids(rightcids))];
    end

    unix(['mkcontrast-sess -analysis ' fullfile(L2_exp.analysis_dir, analysisname) contraststring]);
end
end
