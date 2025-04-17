%% analyze behavioral data for EMFL task
% 
% task data should be in the same directory
% filename as 'log_{subj_name}_{subj_id}.mat'

num_subjs = 25;
all_accs = zeros(length(subjs), 5);

for sid = 1:num_subjs
    
    accs = {0,0,0,0,0};
    
    subj = sprintf('kaneff%02d', sid);
    
    for rid = 1:5
        
        run_data = load(['./log_' subj '_' num2str(rid) '.mat']).log;
        cond_ids = {run_data.block.aud_condition}';
        run_accs = {run_data.answers};
        run_accs = run_accs{1,1};
        
        for bid = 1:length(cond_ids)
            cond = cond_ids{bid};
            if cond ~= 0
                
                corr = run_accs{bid};
                accs{cond} = accs{cond} + corr;
                
            end
        end
        
    end
    
    accs = cell2mat(accs) / 10;
    all_accs(sid, :) = accs;
    
end

avg_accs = mean(all_accs, 1);
x_labels = {'FB', 'FP', 'NW', 'QLT', 'MATH'};
x = [1,2,3,4,5];
figure
bar(x, avg_accs);
xticklabels(x_labels);
