%==========================================================================
% VRPA fMRI Second-Level ANOVA — iVR-shift vs OD-shift
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
%   Second-level 2x3 mixed-design ANOVA comparing iVR-shift (n=16)
%   vs OD-shift (n=14) across three visual field locations
%   (Left, Center, Right).
%
%   Input: First-level Post-Pre contrast images per subject:
%     con_0007.nii = LeftPOSTvsLeftPRE
%     con_0008.nii = CenterPOSTvsCenterPRE
%     con_0009.nii = RightPOSTvsRightPRE
%
%   Design matrix columns:
%     [iVR-shift-Left, iVR-shift-Center, iVR-shift-Right,
%      OD-shift-Left,  OD-shift-Center,  OD-shift-Right]
%
%   Contrasts (6 t-contrasts):
%     1. iVRshift_gt_ODshift_Left
%     2. iVRshift_gt_ODshift_Center
%     3. iVRshift_gt_ODshift_Right
%     4. ODshift_gt_iVRshift_Left
%     5. ODshift_gt_iVRshift_Center
%     6. ODshift_gt_iVRshift_Right
%
% Usage:
%   1. Run VRPA_preprocessing.m and VRPA_subject_level.m first
%   2. Update base_dir, stat_dir, spm_path below
%   3. Run this script
%==========================================================================

%% -------------------------------------------------------------------------
%  USER SETTINGS — update these before running
%  -------------------------------------------------------------------------

% Path to first-level results (output of VRPA_subject_level.m)
base_dir = '/path/to/derivatives/first_level';

% Output directory for second-level ANOVA results
stat_dir = '/path/to/derivatives/second_level/iVRshift_vs_ODshift';
if ~exist(stat_dir, 'dir'), mkdir(stat_dir); end

% Path to grey matter mask
gm_mask = '/path/to/GMmask_apriori_HP.nii,1';

% Path to your SPM12 installation
spm_path = '/path/to/spm12';
addpath(spm_path);

% Subject IDs per group
% iVR-shift: sub-01 to sub-16
% OD-shift:  sub-31 to sub-44
ivr_shift_ids = 1:16;
od_shift_ids  = 31:44;

%% -------------------------------------------------------------------------
%  BUILD SCAN LISTS
%  con_0007 = LeftPOSTvsLeftPRE
%  con_0008 = CenterPOSTvsCenterPRE
%  con_0009 = RightPOSTvsRightPRE
%  -------------------------------------------------------------------------

% iVR-shift scans
scans_ivr_left   = cell(length(ivr_shift_ids), 1);
scans_ivr_center = cell(length(ivr_shift_ids), 1);
scans_ivr_right  = cell(length(ivr_shift_ids), 1);
for i = 1:length(ivr_shift_ids)
    n   = ivr_shift_ids(i);
    sub = sprintf('sub-%02d', n);
    scans_ivr_left{i}   = fullfile(base_dir, sub, 'con_0007.nii,1');
    scans_ivr_center{i} = fullfile(base_dir, sub, 'con_0008.nii,1');
    scans_ivr_right{i}  = fullfile(base_dir, sub, 'con_0009.nii,1');
end

% OD-shift scans
scans_od_left   = cell(length(od_shift_ids), 1);
scans_od_center = cell(length(od_shift_ids), 1);
scans_od_right  = cell(length(od_shift_ids), 1);
for i = 1:length(od_shift_ids)
    n   = od_shift_ids(i);
    sub = sprintf('sub-%02d', n);
    scans_od_left{i}   = fullfile(base_dir, sub, 'con_0007.nii,1');
    scans_od_center{i} = fullfile(base_dir, sub, 'con_0008.nii,1');
    scans_od_right{i}  = fullfile(base_dir, sub, 'con_0009.nii,1');
end

%% -------------------------------------------------------------------------
%  INITIALISE SPM
%  -------------------------------------------------------------------------
spm('defaults', 'fmri');
spm_jobman('initcfg');

%% -------------------------------------------------------------------------
%  STEP 1: Factorial Design Specification
%  2 (Platform: iVR-shift, OD-shift) x 3 (Location: Left, Center, Right)
%  -------------------------------------------------------------------------
matlabbatch{1}.spm.stats.factorial_design.dir = {stat_dir};

% Factor 1: Platform (between-subjects)
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).name     = 'Platform';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).levels   = 2;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).dept     = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).gmsca   = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).ancova  = 0;

% Factor 2: Location (within-subjects)
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).name     = 'Location';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).levels   = 3;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).dept     = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).gmsca   = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).ancova  = 0;

% Cell [1,1]: iVR-shift, Left
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).levels = [1; 1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).scans  = scans_ivr_left;

% Cell [1,2]: iVR-shift, Center
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).levels = [1; 2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).scans  = scans_ivr_center;

% Cell [1,3]: iVR-shift, Right
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).levels = [1; 3];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).scans  = scans_ivr_right;

% Cell [2,1]: OD-shift, Left
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).levels = [2; 1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).scans  = scans_od_left;

% Cell [2,2]: OD-shift, Center
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(5).levels = [2; 2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(5).scans  = scans_od_center;

% Cell [2,3]: OD-shift, Right
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(6).levels = [2; 3];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(6).scans  = scans_od_right;

matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 1;

% Covariates
matlabbatch{1}.spm.stats.factorial_design.cov       = ...
    struct('c',{},'cname',{},'iCFI',{},'iCC',{});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = ...
    struct('files',{},'iCFI',{},'iCC',{});

% Masking — same grey matter mask as iVR Condition analysis
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im         = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em         = {gm_mask};

% Global normalisation
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit         = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm        = 1;

%% -------------------------------------------------------------------------
%  STEP 2: Model Estimation
%  -------------------------------------------------------------------------
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep(...
    'Factorial design specification: SPM.mat File', ...
    substruct('.','val','{}',{1},'.','val','{}',{1}, ...
              '.','val','{}',{1}), ...
    substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

%% -------------------------------------------------------------------------
%  STEP 3: Contrast Estimation
%
%  Design matrix columns:
%  [iVR-shift-Left, iVR-shift-Center, iVR-shift-Right,
%   OD-shift-Left,  OD-shift-Center,  OD-shift-Right]
%  -------------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep(...
    'Model estimation: SPM.mat File', ...
    substruct('.','val','{}',{2},'.','val','{}',{1}, ...
              '.','val','{}',{1}), ...
    substruct('.','spmmat'));

%------------------------------------------------------------------
% T-contrast 1: iVR-shift > OD-shift for Left
%------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name    = 'iVRshift_gt_ODshift_Left';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec  = [1  0  0 -1  0  0];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

%------------------------------------------------------------------
% T-contrast 2: iVR-shift > OD-shift for Center
%------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name    = 'iVRshift_gt_ODshift_Center';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.convec  = [0  1  0  0 -1  0];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

%------------------------------------------------------------------
% T-contrast 3: iVR-shift > OD-shift for Right
%------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.consess{3}.tcon.name    = 'iVRshift_gt_ODshift_Right';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.convec  = [0  0  1  0  0 -1];
matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';

%------------------------------------------------------------------
% T-contrast 4: OD-shift > iVR-shift for Left
%------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.consess{4}.tcon.name    = 'ODshift_gt_iVRshift_Left';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.convec  = [-1  0  0  1  0  0];
matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';

%------------------------------------------------------------------
% T-contrast 5: OD-shift > iVR-shift for Center
%------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.consess{5}.tcon.name    = 'ODshift_gt_iVRshift_Center';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.convec  = [0 -1  0  0  1  0];
matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';

%------------------------------------------------------------------
% T-contrast 6: OD-shift > iVR-shift for Right
%------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.consess{6}.tcon.name    = 'ODshift_gt_iVRshift_Right';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.convec  = [0  0 -1  0  0  1];
matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.delete = 0;

%% -------------------------------------------------------------------------
%  RUN
%  -------------------------------------------------------------------------
spm_jobman('run', matlabbatch);

fprintf('\n========================================\n');
fprintf('Second-level ANOVA complete: iVR-shift vs OD-shift\n');
fprintf('Results saved in: %s\n', stat_dir);
fprintf('========================================\n');
