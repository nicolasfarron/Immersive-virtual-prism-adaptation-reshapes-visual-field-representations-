%==========================================================================
% VRPA fMRI First-Level GLM — All 58 subjects
%==========================================================================
% Study: Immersive virtual prism adaptation reshapes visual field
%        representations in the inferior parietal lobule
%
% Authors: Farron N, Wilf M, Perez-Marcos D, Perrin H, Serino A,
%          Clarke S, Crottaz-Herbette S
%
% Software: SPM12 (v7487), MATLAB R2023b
%
% Description:
%   First-level GLM specification, estimation and contrast computation
%   for all 58 subjects. Input data should be downloaded from OpenNeuro:
%   https://doi.org/10.18112/openneuro.dsXXXXX.v1.0.0
%
%   The GLM models two fMRI sessions:
%     ses-01: Pre-adaptation  (Attention1)
%     ses-02: Post-adaptation (Attention2)
%
%   Three conditions per session:
%     - StarsLeft   (visual target in left visual field)
%     - StarsCenter (visual target in central visual field)
%     - StarsRight  (visual target in right visual field)
%
%   Six motion regressors per session included as nuisance regressors.
%
%   Contrasts estimated per subject:
%     Con 1: LEFT_Pre
%     Con 2: CENTER_Pre
%     Con 3: RIGHT_Pre
%     Con 4: LEFT_Post
%     Con 5: CENTER_Post
%     Con 6: RIGHT_Post
%     Con 7: LeftPOSTvsLeftPRE
%     Con 8: CenterPOSTvsCenterPRE
%     Con 9: RightPOSTvsRightPRE
%
%   Note on counterbalancing:
%   Left/Right stimulus onsets are counterbalanced between ses-01 and
%   ses-02 — Left onsets in ses-02 correspond to Right onsets in ses-01.
%
% Subject groups:
%   sub-01 to sub-16: iVR-shift
%   sub-17 to sub-30: iVR-ctrl
%   sub-31 to sub-44: OD-shift
%   sub-45 to sub-58: OD-ctrl
%
% Usage:
%   1. Download dataset from OpenNeuro
%   2. Run VRPA_preprocessing.m first
%   3. Update base_dir, stat_dir and spm_path below
%   4. Run — the script loops over all subjects automatically
%==========================================================================

%% -------------------------------------------------------------------------
%  USER SETTINGS — update these before running
%  -------------------------------------------------------------------------

% Path to downloaded OpenNeuro dataset
base_dir = '/path/to/BIDS_dataset_final';

% Path to output directory for SPM first-level results
% This should be OUTSIDE the BIDS dataset folder
stat_dir = '/path/to/derivatives/first_level';

% Path to your SPM12 installation
spm_path = '/path/to/spm12';
addpath(spm_path);

%% -------------------------------------------------------------------------
%  ACQUISITION PARAMETERS
%  -------------------------------------------------------------------------
Nvol          = 202;   % Number of functional volumes per session
TR            = 2;     % Repetition time (seconds)
stim_duration = 0.5;   % Stimulus duration (seconds)

%% -------------------------------------------------------------------------
%  CONDITION ONSETS (seconds) — fixed across all subjects
%  Stimuli were presented in a fixed pseudorandom order
%  identical across all participants
%  -------------------------------------------------------------------------

% Session 1: Pre-adaptation
onsets_left_pre   = [12;38;47;58;84;143;182;192;215;229; ...
                     243;265;275;296;299;330;339;361;386;390];
onsets_center_pre = [5;27;32;35;42;50;67;74;135;155; ...
                     204;208;225;252;255;271;303;308;366;376];
onsets_right_pre  = [9;15;80;91;101;104;132;148;169;174; ...
                     219;237;286;289;311;327;334;345;348;358];

% Session 2: Post-adaptation
% Left/Right onsets counterbalanced between sessions
onsets_left_post   = onsets_right_pre;
onsets_center_post = onsets_left_pre;
onsets_right_post  = onsets_center_pre;

%% -------------------------------------------------------------------------
%  INITIALISE SPM
%  -------------------------------------------------------------------------
spm('defaults', 'fmri');
spm_jobman('initcfg');

%% -------------------------------------------------------------------------
%  MAIN LOOP — all 58 subjects
%  -------------------------------------------------------------------------
for n = 1:58

    bids_id = sprintf('sub-%02d', n);
    sub_dir = fullfile(base_dir, bids_id);

    fprintf('\n========================================\n');
    fprintf('Processing: %s (%d/58)\n', bids_id, n);
    fprintf('========================================\n');

    % Check subject folder exists
    if ~exist(sub_dir, 'dir')
        fprintf('WARNING: %s not found — skipping\n', bids_id);
        continue
    end

    % Functional directories
    func_dir1 = fullfile(sub_dir, 'ses-01', 'func');
    func_dir2 = fullfile(sub_dir, 'ses-02', 'func');

    % Output directory for this subject
    sub_stat_dir = fullfile(stat_dir, bids_id);
    if ~exist(sub_stat_dir, 'dir')
        mkdir(sub_stat_dir);
    end

    % Build preprocessed scan file lists
    % Preprocessed files have prefix 'swar' added by preprocessing script
    scans1 = cell(Nvol, 1);
    scans2 = cell(Nvol, 1);
    for j = 1:Nvol
        scans1{j} = fullfile(func_dir1, ...
                             sprintf('swar%s_ses-01_task-detection_bold_%04d.nii,1', ...
                                     bids_id, j));
        scans2{j} = fullfile(func_dir2, ...
                             sprintf('swar%s_ses-02_task-detection_bold_%04d.nii,1', ...
                                     bids_id, j));
    end

    % Motion regressor files (generated by preprocessing script)
    motion_file1 = fullfile(func_dir1, ...
                            sprintf('rp_%s_ses-01_task-detection_bold_0001.txt', ...
                                    bids_id));
    motion_file2 = fullfile(func_dir2, ...
                            sprintf('rp_%s_ses-02_task-detection_bold_0001.txt', ...
                                    bids_id));

    %----------------------------------------------------------------------
    % STEP 1: fMRI Model Specification
    %----------------------------------------------------------------------
    matlabbatch{1}.spm.stats.fmri_spec.dir            = {sub_stat_dir};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units   = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT      = TR;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t  = 32;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;

    % --- Session 1: Pre-adaptation ---
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = scans1;

    % Condition 1: Left (Pre)
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).name     = 'StarsLeftPre';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).onset    = onsets_left_pre;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).duration = stim_duration;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).tmod     = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).pmod     = ...
        struct('name',{},'param',{},'poly',{});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).orth     = 1;

    % Condition 2: Center (Pre)
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).name     = 'StarsCenterPre';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).onset    = onsets_center_pre;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).duration = stim_duration;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).tmod     = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).pmod     = ...
        struct('name',{},'param',{},'poly',{});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).orth     = 1;

    % Condition 3: Right (Pre)
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).name     = 'StarsRightPre';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).onset    = onsets_right_pre;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).duration = stim_duration;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).tmod     = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).pmod     = ...
        struct('name',{},'param',{},'poly',{});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(3).orth     = 1;

    % Motion regressors session 1
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi     = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress   = ...
        struct('name',{},'val',{});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {motion_file1};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf       = 128;

    % --- Session 2: Post-adaptation ---
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans = scans2;

    % Condition 1: Left (Post)
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).name     = 'StarsLeftPost';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).onset    = onsets_left_post;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).duration = stim_duration;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).tmod     = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).pmod     = ...
        struct('name',{},'param',{},'poly',{});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).orth     = 1;

    % Condition 2: Center (Post)
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).name     = 'StarsCenterPost';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).onset    = onsets_center_post;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).duration = stim_duration;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).tmod     = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).pmod     = ...
        struct('name',{},'param',{},'poly',{});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).orth     = 1;

    % Condition 3: Right (Post)
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).name     = 'StarsRightPost';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).onset    = onsets_right_post;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).duration = stim_duration;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).tmod     = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).pmod     = ...
        struct('name',{},'param',{},'poly',{});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(3).orth     = 1;

    % Motion regressors session 2
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi     = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).regress   = ...
        struct('name',{},'val',{});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {motion_file2};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).hpf       = 128;

    % GLM settings
    matlabbatch{1}.spm.stats.fmri_spec.fact             = ...
        struct('name',{},'levels',{});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt             = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global           = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mask             = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi              = 'AR(1)';

    %----------------------------------------------------------------------
    % STEP 2: Model Estimation
    %----------------------------------------------------------------------
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep(...
        'fMRI model specification: SPM.mat File', ...
        substruct('.','val','{}',{1},'.','val','{}',{1}, ...
                  '.','val','{}',{1}), ...
        substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    %----------------------------------------------------------------------
    % STEP 3: Contrast Estimation
    %----------------------------------------------------------------------
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep(...
        'Model estimation: SPM.mat File', ...
        substruct('.','val','{}',{2},'.','val','{}',{1}, ...
                  '.','val','{}',{1}), ...
        substruct('.','spmmat'));

    % Simple contrasts — single condition activations
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name    = 'LEFT_Pre';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec  = 1;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name    = 'CENTER_Pre';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.convec  = [0 1];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{3}.tcon.name    = 'RIGHT_Pre';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.convec  = [0 0 1];
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{4}.tcon.name    = 'LEFT_Post';
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.convec  = ...
        [0 0 0 0 0 0 0 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{5}.tcon.name    = 'CENTER_Post';
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.convec  = ...
        [0 0 0 0 0 0 0 0 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{6}.tcon.name    = 'RIGHT_Post';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.convec  = ...
        [0 0 0 0 0 0 0 0 0 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';

    % Post > Pre contrasts — adaptation effects per visual field location
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.name    = 'LeftPOSTvsLeftPRE';
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.convec  = ...
        [-1 0 0 0 0 0 0 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{8}.tcon.name    = 'CenterPOSTvsCenterPRE';
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.convec  = ...
        [0 -1 0 0 0 0 0 0 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.consess{9}.tcon.name    = 'RightPOSTvsRightPRE';
    matlabbatch{3}.spm.stats.con.consess{9}.tcon.convec  = ...
        [0 0 -1 0 0 0 0 0 0 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{9}.tcon.sessrep = 'none';

    matlabbatch{3}.spm.stats.con.delete = 0;

    %----------------------------------------------------------------------
    % RUN BATCH
    %----------------------------------------------------------------------
    spm_jobman('run', matlabbatch);
    fprintf('Completed: %s\n', bids_id);
    clear matlabbatch scans1 scans2

end

fprintf('\n========================================\n');
fprintf('First-level GLM complete for all 58 subjects.\n');
fprintf('========================================\n');
