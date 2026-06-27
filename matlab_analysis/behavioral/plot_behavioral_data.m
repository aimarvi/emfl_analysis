%% analyze behavioral data for the emfl auditory task
% expect task log files in matlab_analysis/ with names like
% log_kaneff01_1.mat

dir_matlab_analysis = fileparts(mfilename('fullpath'));

num_subjects = 25;
num_runs = 5;
num_conditions = 5;
all_accuracies = zeros(num_subjects, num_conditions);

for subject_index = 1:num_subjects
    subject_accuracies = zeros(1, num_conditions);
    subject_name = sprintf('kaneff%02d', subject_index);

    for run_index = 1:num_runs
        filepath_log = fullfile(dir_matlab_analysis, ['log_' subject_name '_' num2str(run_index) '.mat']);
        log_data = load(filepath_log).log;

        condition_ids = {log_data.block.aud_condition}';
        run_answers = {log_data.answers};
        run_answers = run_answers{1,1};

        for block_index = 1:length(condition_ids)
            condition_id = condition_ids{block_index};
            if condition_id ~= 0
                subject_accuracies(condition_id) = subject_accuracies(condition_id) + run_answers{block_index};
            end
        end
    end

    all_accuracies(subject_index, :) = subject_accuracies / 10;
end

mean_accuracies = mean(all_accuracies, 1);
condition_labels = {'FB', 'FP', 'NW', 'QLT', 'MATH'};
condition_positions = 1:num_conditions;

figure
bar(condition_positions, mean_accuracies);
xticklabels(condition_labels);
