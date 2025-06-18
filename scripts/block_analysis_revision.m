function [] = block_analysis_revision(subj_id,exp_name, unpackFlag, preprocFlag,makeAnalysisFlag,...
    runAnalysisFlag, glmSingleFlag, volumeFlag, surfaceFlag, smoothing, para_stem, para_ext)
%% fMRI Block Design Analysis
% Efficient Localizer

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

%copy para files and make run list files
fprintf ('Copying para files...\n');
for r=1:length(L2.(exp_name).run_ids)
    unix(['rsync -av ' L2.(exp_name).paras_dir '/' subj_id '/' para_stem num2str(r) para_ext ' '...
    L2.(exp_name).functional_dir '/bold/' sprintf('%03d',L2.(exp_name).run_ids(r)) '/' exp_name '.para'])
end

fprintf ('Creating RunListFiles...\n');
% unix(['rm -f ' L2.(exp_name).functional_dir '/bold/*.rlf'])
for r=1:length(L2.(exp_name).run_ids)
    if r<4 %if first half
        unix(['echo ' sprintf('%03d',L2.(exp_name).run_ids(r)) ' >> ' L2.(exp_name).functional_dir '/bold/' exp_name '_first.rlf'])
    else  %if last half
        unix(['echo ' sprintf('%03d',L2.(exp_name).run_ids(r)) ' >> ' L2.(exp_name).functional_dir '/bold/' exp_name '_last.rlf'])
    end
end

%% make analysis plans
if(makeAnalysisFlag)
        
    if(volumeFlag)
        splits={'first' 'last'};
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
        splits={'first' 'last'};
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
        splits={'first' 'last'};
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
        splits={'first' 'last'};
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


end
