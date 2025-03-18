function [] = block_analysis_final(subj_id,exp_name, unpackFlag, preprocFlag,makeAnalysisFlag,...
    runAnalysisFlag, glmSingleFlag, volumeFlag, surfaceFlag, smoothing, para_stem, para_ext)
%% fMRI Block Design Analysis
% Efficient Localizer
% called by prep_analysis_final() for standard fMRI analysis
% 
% args:
%     subj_id (str): subject name
%     exp_name (str): localizer name (eg. 'vis', 'aud')
%     flags (int): [0,1]
%         unpack: unpack dicoms
%     preproc: apply standard preprocessing steps
%         makeAnalysis: set up the analysis parameters
%         runAnalysis: run the actual analysis using the FS-FAST pipeline
%         glmSingle: run the actual analysis using the GLMsingle pipeline
%         volume: run the analysis in volume space
%         surface: run the analysis in surface space
%     smoothing (int): full-width half-maximum smoothing to apply to the data (in mm)
%     para_stem (str): prefix of paradigm file name before the run number (eg. '{subj_id}_run')
%     para_ext (str): suffix of paradigm file name after the run number, including file extension (eg. '_{exp_name}.para')

%% Setup

%get project directory
cd ..
project_dir = pwd;
cd ./scripts

%Load L2
eval(['load ' project_dir '/analysis/L2_' subj_id '.mat;']);
fprintf ('L2 structure loaded successfully... \n');

%Create directories
unix(['mkdir -p ' L2.(exp_name).functional_dir '/bold/'])

%Create subj_id file (overwrites existing)
unix(['echo ' subj_id ' > ' L2.(exp_name).functional_dir '/subjectname'])

%% Unpack

if (unpackFlag)
    subjname = subj_id;
    dicomname = L2.(exp_name).dicom_name;
    
    projectdir = L2.(exp_name).project_dir;
    localiserids = {exp_name};
    functionalruns{1} = L2.(exp_name).run_ids;
    
    sourcefolder = [L2.(exp_name).dicoms_dir '/' dicomname];
    
    for funcid = 1:length(localiserids)
        fprintf('Unpacking all the functional scans from %s\n', localiserids{funcid});
        targetfoldername = [projectdir '/vols_' localiserids{funcid} '/' subjname '/'];
        funcruns = functionalruns{funcid};
        
        unpackstring = ['unpacksdcmdir -src ' sourcefolder ... 
                              ' -targ ' targetfoldername];
        c = 0;
        for runid = 1:length(funcruns)
            c= c+1; string{c} = [unpackstring ' -run ' num2str(funcruns(runid)) ' bold nii f.nii.gz'];
        end
        
        for cid = 1:length(string)
            torun = string{cid};
            fprintf('Executing: %s \n',torun);
            unix(torun);
        end
        
        fprintf('Unpack successful: Copy over para files to the folders \n'); 

        pause(1);
    end
end

%% do preprocessing
if(preprocFlag)
    fprintf('\n\nPreprocessing data \n\n');
    unix(['preproc-sess -s ' subj_id ...
                       ' -d ' L2.(exp_name).functional_dir '/..' ...
                       ' -per-run' ...
                       ' -fsd bold -fwhm ' smoothing ...
                       ' -force'])

    fprintf('\n\nTransforming data to Anatomical \n\n');
    
    if(~exist('smoothing'))
        smoothing = '0'; 
    end
    
    for r=1:length(L2.(exp_name).run_ids)
        unix(['mri_vol2vol --reg ' L2.(exp_name).functional_dir '/bold/' sprintf('%03d',L2.(exp_name).run_ids(r)) '/' ...
              'register.dof6.lta '...
              '--mov '  L2.(exp_name).functional_dir '/bold/' sprintf('%03d',L2.(exp_name).run_ids(r)) '/fmcpr.sm' smoothing '.nii.gz ' ...
              '--fstarg '...
              '--no-resample '...
              '--o ' L2.(exp_name).functional_dir '/bold/' sprintf('%03d',L2.(exp_name).run_ids(r)) '/fmcpr_reg.sm' smoothing '.nii.gz '...
              ]);
    end
    
else
    fprintf('\n\nSkipping preprocessing steps... \n\n');
end

%copy para files and make run list files
fprintf ('Copying para files...\n');
for r=1:length(L2.(exp_name).run_ids)
    unix(['rsync -av ' L2.(exp_name).paras_dir '/' subj_id '/' para_stem num2str(r) para_ext ' '...
    L2.(exp_name).functional_dir '/bold/' sprintf('%03d',L2.(exp_name).run_ids(r)) '/' exp_name '.para'])
end

fprintf ('Creating RunListFiles...\n');
unix(['rm -f ' L2.(exp_name).functional_dir '/bold/*.rlf'])
for r=1:length(L2.(exp_name).run_ids)
    if rem(r,2)==0 %if even
        unix(['echo ' sprintf('%03d',L2.(exp_name).run_ids(r)) ' >> ' L2.(exp_name).functional_dir '/bold/' exp_name '_all.rlf'])
        unix(['echo ' sprintf('%03d',L2.(exp_name).run_ids(r)) ' >> ' L2.(exp_name).functional_dir '/bold/' exp_name '_even.rlf'])
    else  %if odd
        unix(['echo ' sprintf('%03d',L2.(exp_name).run_ids(r)) ' >> ' L2.(exp_name).functional_dir '/bold/' exp_name '_all.rlf'])
        unix(['echo ' sprintf('%03d',L2.(exp_name).run_ids(r)) ' >> ' L2.(exp_name).functional_dir '/bold/' exp_name '_odd.rlf'])
    end
end

%% make analysis plans
if(makeAnalysisFlag)
        
    if(volumeFlag)
        splits={'all' 'even' 'odd'};
        for s=1:length(splits)
            split=splits{s};
            
            %' -nuisreg mcprextreg ' int2str(num_ext_regs)...
            unix(['mkanalysis-sess -a ' L2.(exp_name).analysis_dir '/' exp_name '.sm' smoothing '.' split ...
                ' -native'...
                ' -funcstem fmcpr_reg.sm' smoothing ...
                ' -fsd bold' ...
                ' -event-related' ...
                ' -paradigm ' L2.(exp_name).para_name ...
                ' -nconditions ' num2str(L2.(exp_name).num_conditions) ...
                ' -refeventdur ' num2str(L2.(exp_name).block_length) ...
                ' -nuisreg mcprextreg 6'...
                ' -force'...
                ' -TR ' num2str(L2.(exp_name).TR) ...
                ' -polyfit 1' ...
                ' -spmhrf 0' ...
                ' -runlistfile ' exp_name '_' split '.rlf']);

            for contrastid = 1:length(L2.(exp_name).contrasts.names)
                analysisname=[exp_name '.sm' smoothing '.' split];
                contraststring = [' -contrast ' L2.(exp_name).contrasts.names{contrastid}];
                lids = L2.(exp_name).contrasts.cidleft{contrastid}; 
                rids = L2.(exp_name).contrasts.cidright{contrastid}; 
                % The left sides go in first
                for leftcids = 1:length(lids)
                    contraststring = [contraststring ' -a ' num2str(lids(leftcids))];
                end
                % The right side of the contrasts go next
                for rightcids = 1:length(rids)
                    contraststring = [contraststring ' -c ' num2str(rids(rightcids))];
                end
                % Add to final string
                unix(['mkcontrast-sess -analysis ' L2.(exp_name).analysis_dir '/' analysisname contraststring]);
            end
        end
    end

    if(surfaceFlag)
        splits={'all' 'even' 'odd'};
        hemis={'rh' 'lh'};
        for h=1:length(hemis)
            hemi=hemis{h};
            for s=1:length(splits)
                split=splits{s};
                unix(['mkanalysis-sess -a ' L2.(exp_name).analysis_dir '/' exp_name '.sm' smoothing '.' split '.' hemi ...
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
                    ' -mcextreg ' ...
                    ' -runlistfile ' exp_name '_' split '.rlf' ...
                    ' -per-session'])

                for contrastid = 1:length(L2.(exp_name).contrasts.names)
                    analysisname=[exp_name '.sm' smoothing '.' split '.' hemi];
                    contraststring = [' -contrast ' L2.(exp_name).contrasts.names{contrastid}];
                    lids = L2.(exp_name).contrasts.cidleft{contrastid}; 
                    rids = L2.(exp_name).contrasts.cidright{contrastid}; 
                    % The left sides go in first
                    for leftcids = 1:length(lids)
                        contraststring = [contraststring ' -a ' num2str(lids(leftcids))];
                    end
                    % The right side of the contrasts go next
                    for rightcids = 1:length(rids)
                        contraststring = [contraststring ' -c ' num2str(rids(rightcids))];
                    end
                    % Add to final string
                    unix(['mkcontrast-sess -analysis ' L2.(exp_name).analysis_dir '/' analysisname contraststring]);
                end
            end
        end
    end
end

%% run the analyses!!!
if(runAnalysisFlag)
    if(volumeFlag)
        workingDir=pwd;
        cd(L2.(exp_name).analysis_dir)
        splits={'all' 'even' 'odd'};
        for s=1:length(splits)
            split=splits{s};
            analysisname=[exp_name '.sm' smoothing '.' split];
            unix(['selxavg3-sess -s ' subj_id ' -d ' L2.(exp_name).functional_dir '/.. -analysis ' analysisname ' -no-preproc -overwrite'])
        end
        cd(workingDir)
    end

    if(surfaceFlag)
        workingDir=pwd;
        cd(L2.(exp_name).analysis_dir)
        splits={'all' 'even' 'odd'};
        hemis={'rh' 'lh'};
        for h=1:length(hemis)
            hemi=hemis{h};
            for s=1:length(splits)
                split=splits{s};
                analysisname=[exp_name '.sm' smoothing '.' split '.' hemi];
                unix(['selxavg3-sess -s ' subj_id ' -d ' L2.(exp_name).functional_dir '/.. -analysis ' analysisname ' -overwrite'])
            end
        end
        cd(workingDir)
    end
end

%% GLMsingle!

if (glmSingleFlag)
    
    %get necessary functions
    addpath(genpath('/om2/user/samhutch/GLMsingle'));
    
    if (volumeFlag)
        
        fprintf('Processing volume data\n');
        
        file_name = ['fmcpr.sm' (smoothing) '.nii.gz']; %use motion corrected, smoothed data
        runs = L2.(exp_name).run_ids;
        for r=1:length(runs)
            
            %read functional data
            file = [L2.(exp_name).functional_dir '/bold/' num2str(runs(r),'%03d') '/' (file_name)];;
            data = MRIread(file); %get the .nii.gz file to a format GLMsingle can use
            data = squeeze(data.vol); %remove unnecessary dimensions
            run_data{r} = single(data); %reduce to single-precision accuracy and store
            
            %read para file -> design matrix
            para_name = [L2.(exp_name).functional_dir '/bold/' num2str(runs(r),'%03d') '/' (exp_name) '.para'];
            vars = read_parafile(para_name);
            design{r} = get_design(vars, size(run_data{r}, 4), L2.(exp_name).num_conditions, L2.(exp_name).TR);
            
        end
        
        fprintf('Running GLMsingle on all runs\n');
        
        output_dir = [L2.(exp_name).functional_dir '/bold/GLMsingle_results'];
        unix(['mkdir -p ' output_dir]);
        stimdur = L2.(exp_name).block_length;
        tr = L2.(exp_name).TR;
        
        [~,~,convmat,cache] = GLMestimatesingletrial(design, run_data, stimdur, tr, output_dir);
        
        %save convolved design matrix
        save([output_dir '/convmat.mat'], 'convmat', '-v7.3');
        
        %save a bunch of cached data from model fitting
        save([output_dir '/cache.mat'], 'cache', '-v7.3');
        
        %load betas for further analysis
        modelD = load([output_dir '/TYPED_FITHRF_GLMDENOISE_RR.mat']);
        betasD = modelD.modelmd;
        
        modelC = load([output_dir '/TYPEC_FITHRF_GLMDENOISE.mat']);
        betasC = modelC.modelmd;
        
        save([output_dir '/betas_trialsD.mat'], 'betasD', '-v7.3');
        save([output_dir '/betas_trialsC.mat'], 'betasC', '-v7.3');
        
        %THE FOLLOWING BETA-REARRANGEMENT IS FROM
        %https://htmlpreview.github.io/?https://github.com/kendrickkay/GLMsingle/blob/main/matlab/examples/example2preview/example2.html
        
        %find where each condition is in the design
        design_concat = cat(1,design{:});
        cond_order = [];
        for p=1:size(design_concat,1)
            if any(design_concat(p,:))
                cond_order = [cond_order find(design_concat(p,:))];
            end
        end
        
        %reorganize betas as X x Y x Z x Trials x Conditions
        x = size(betasD, 1);
        y = size(betasD, 2);
        z = size(betasD, 3);
        num_conditions = size(design{1}, 2);
        num_trials = size(betasD, 4)/num_conditions;
        
        new_betasD = nan(x, y, z, num_trials, num_conditions);
        new_betasC = nan(x, y, z, num_trials, num_conditions);
        
        for c=1:L2.(exp_name).num_conditions
            fprintf('Condition %i was repeated %i times, with GLMsingle betas at the following indices:\n',c, length(find(cond_order==1)));
            indicies = find(cond_order==c);
            
            cond_betasD = betasD(:,:,:,indicies);
            new_betasD(:,:,:,:,c) = cond_betasD;
            
            cond_betasC = betasC(:,:,:,indicies);
            new_betasC(:,:,:,:,c) = cond_betasC;
        end
        
        save([output_dir '/betas_conditionsD.mat'], 'new_betasD', '-v7.3');
        save([output_dir '/betas_conditionsC.mat'], 'new_betasC', '-v7.3');
        
    end
    
    if (surfaceFlag)
        
    end
    
end

end
