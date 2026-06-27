function [] = block_analysis_revision(subj_id, exp_name, unpackFlag, preprocFlag, makeAnalysisFlag, ...
    runAnalysisFlag, glmSingleFlag, volumeFlag, surfaceFlag, smoothing, para_stem, para_ext)
%% fmri block design analysis
% revision workflow using first/last run splits instead of odd/even.

%% setup

paths = emfl_paths();
filepath_l2 = fullfile(paths.analysis_dir, ['L2_' subj_id '.mat']);
load(filepath_l2, 'L2');
fprintf('L2 structure loaded successfully.\n');

mkdir(fullfile(L2.(exp_name).functional_dir, 'bold'));
write_subject_name_file(subj_id, L2.(exp_name).functional_dir);

%% copy para files and create run lists

copy_para_files(L2.(exp_name), subj_id, exp_name, para_stem, para_ext);
create_runlist_files(L2.(exp_name), exp_name);

%% build analysis plans

if makeAnalysisFlag
    if volumeFlag
        splits = {'first', 'last'};
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
        splits = {'first', 'last'};
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
        splits = {'first', 'last'};
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
        splits = {'first', 'last'};
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

function create_runlist_files(L2_exp, exp_name)
fprintf('Creating run list files.\n');
for r = 1:length(L2_exp.run_ids)
    run_label = sprintf('%03d', L2_exp.run_ids(r));
    if r < 4
        filepath_split = fullfile(L2_exp.functional_dir, 'bold', [exp_name '_first.rlf']);
    else
        filepath_split = fullfile(L2_exp.functional_dir, 'bold', [exp_name '_last.rlf']);
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

    for leftcids = 1:length(lids)
        contraststring = [contraststring ' -a ' num2str(lids(leftcids))];
    end

    for rightcids = 1:length(rids)
        contraststring = [contraststring ' -c ' num2str(rids(rightcids))];
    end

    unix(['mkcontrast-sess -analysis ' fullfile(L2_exp.analysis_dir, analysisname) contraststring]);
end
end
