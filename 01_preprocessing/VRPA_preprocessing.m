%==========================================================================
% VRPA fMRI Preprocessing Pipeline
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
%   Full preprocessing pipeline applied to all 58 subjects.
%   Input data should be downloaded from OpenNeuro:
%   https://doi.org/10.18112/openneuro.dsXXXXX.v1.0.0
%
% Pipeline steps:
%   1. Realignment (motion correction) — Estimate & Reslice
%   2. Slice timing correction
%   3. Coregistration of structural to mean functional
%   4. Normalisation to MNI space — Estimate & Write (functional)
%   5. Normalisation — Write only (structural)
%   6. Spatial smoothing (6mm FWHM)
%
% Input BIDS structure:
%   sub-XX/ses-01/anat/sub-XX_ses-01_T1w.nii
%   sub-XX/ses-01/func/sub-XX_ses-01_task-detection_bold_XXXX.nii
%   sub-XX/ses-02/func/sub-XX_ses-02_task-detection_bold_XXXX.nii
%
% Subject groups:
%   sub-01 to sub-16: iVR-shift (iVR acquisition parameters)
%   sub-17 to sub-30: iVR-ctrl  (iVR acquisition parameters)
%   sub-31 to sub-44: OD-shift  (OD acquisition parameters)
%   sub-45 to sub-58: OD-ctrl   (OD acquisition parameters)
%
% Output: Preprocessed files with prefix 'swar'
%         (smoothed, normalised, slice-timing corrected, realigned)
%
% Usage:
%   1. Download dataset from OpenNeuro
%   2. Update base_dir and spm_path below
%   3. Run — the script loops over all subjects automatically
%==========================================================================

%% -------------------------------------------------------------------------
%  USER SETTINGS — update these before running
%  -------------------------------------------------------------------------

% Path to downloaded OpenNeuro dataset
base_dir = '/path/to/BIDS_dataset_final';

% Path to your SPM12 installation
spm_path = '/path/to/spm12';
addpath(spm_path);

%% -------------------------------------------------------------------------
%  ACQUISITION PARAMETERS
%  -------------------------------------------------------------------------

% iVR groups acquisition parameters (sub-01 to sub-30)
ivr_params.nslices      = 64;
ivr_params.TR           = 2;
ivr_params.TA           = ivr_params.TR - (ivr_params.TR / ivr_params.nslices);
ivr_params.slice_timing = [1.485 0 0.990 0.063 1.053 ...
                            0.125 1.115 0.188 1.178 0.248 ...
                            1.238 0.310 1.300 0.373 1.363 ...
                            0.435 1.425 0.558 1.548 0.620 ...
                            1.610 0.683 1.670 0.742 1.733 ...
                            0.805 1.795 0.868 1.858 0.930 ...
                            1.918 0.495 1.485 0 0.990 0.063 ...
                            1.053 0.125 1.115 0.188 1.178 0.248 ...
                            1.238 0.310 1.300 0.373 1.363 0.435 ...
                            1.425 0.558 1.548 0.620 1.610 0.683 ...
                            1.670 0.742 1.733 0.805 1.795 0.868 ...
                            1.858 0.930 1.918 0.495];
ivr_params.ref_slice    = 0;

% OD groups acquisition parameters (sub-31 to sub-58)
od_params.nslices       = 32;
od_params.TR            = 2;
od_params.TA            = od_params.TR - (od_params.TR / od_params.nslices);
od_params.slice_timing  = (0:od_params.nslices-1) * ...
                           (od_params.TR / od_params.nslices);
od_params.ref_slice     = 0;

% Common parameters
Nvol        = 202;
smooth_fwhm = [6 6 6];
bb          = [-78 -112 -70; 78 76 85];
vox         = [2 2 2];

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

    % Select acquisition parameters based on subject number
    if n <= 30
        params = ivr_params;
        fprintf('Parameters: iVR (64 slices, 2x2x2mm)\n');
    else
        params = od_params;
        fprintf('Parameters: OD (32 slices, 3x3x3mm)\n');
    end

    % Build file paths
    anat_dir  = fullfile(sub_dir, 'ses-01', 'anat');
    func_dir1 = fullfile(sub_dir, 'ses-01', 'func');
    func_dir2 = fullfile(sub_dir, 'ses-02', 'func');

    % Structural file
    t1w_file  = fullfile(anat_dir, [bids_id '_ses-01_T1w.nii,1']);

    % Build functional scan lists
    scans1 = cell(Nvol, 1);
    scans2 = cell(Nvol, 1);
    for j = 1:Nvol
        scans1{j} = fullfile(func_dir1, ...
                             sprintf('%s_ses-01_task-detection_bold_%04d.nii,1', ...
                                     bids_id, j));
        scans2{j} = fullfile(func_dir2, ...
                             sprintf('%s_ses-02_task-detection_bold_%04d.nii,1', ...
                                     bids_id, j));
    end
    scans = {scans1, scans2};

    %----------------------------------------------------------------------
    % STEP 1: Realignment — Estimate & Reslice
    %----------------------------------------------------------------------
    matlabbatch{1}.spm.spatial.realign.estwrite.data = scans;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep     = 4;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm    = 5;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm     = 1;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp  = 2;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap    = [0 0 0];
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight  = {''};
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which   = [2 1];
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp  = 4;
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap    = [0 0 0];
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask    = 1;
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix  = 'r';

    %----------------------------------------------------------------------
    % STEP 2: Slice Timing Correction
    %----------------------------------------------------------------------
    matlabbatch{2}.spm.temporal.st.scans{1}(1) = cfg_dep(...
        'Realign: Estimate & Reslice: Resliced Images (Sess 1)', ...
        substruct('.','val','{}',{1},'.','val','{}',{1}, ...
                  '.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','sess','()',{1},'.','rfiles'));
    matlabbatch{2}.spm.temporal.st.scans{2}(1) = cfg_dep(...
        'Realign: Estimate & Reslice: Resliced Images (Sess 2)', ...
        substruct('.','val','{}',{1},'.','val','{}',{1}, ...
                  '.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','sess','()',{2},'.','rfiles'));
    matlabbatch{2}.spm.temporal.st.nslices  = params.nslices;
    matlabbatch{2}.spm.temporal.st.tr       = params.TR;
    matlabbatch{2}.spm.temporal.st.ta       = params.TA;
    matlabbatch{2}.spm.temporal.st.so       = params.slice_timing;
    matlabbatch{2}.spm.temporal.st.refslice = params.ref_slice;
    matlabbatch{2}.spm.temporal.st.prefix   = 'a';

    %----------------------------------------------------------------------
    % STEP 3: Coregistration — structural to mean functional
    %----------------------------------------------------------------------
    matlabbatch{3}.spm.spatial.coreg.estimate.ref(1) = cfg_dep(...
        'Realign: Estimate & Reslice: Mean Image', ...
        substruct('.','val','{}',{1},'.','val','{}',{1}, ...
                  '.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','rmean'));
    matlabbatch{3}.spm.spatial.coreg.estimate.source       = {t1w_file};
    matlabbatch{3}.spm.spatial.coreg.estimate.other        = {''};
    matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = ...
        [0.02 0.02 0.02 0.001 0.001 0.001 ...
         0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

    %----------------------------------------------------------------------
    % STEP 4: Normalisation — Estimate & Write (functional)
    %----------------------------------------------------------------------
    matlabbatch{4}.spm.spatial.normalise.estwrite.subj.vol(1) = cfg_dep(...
        'Realign: Estimate & Reslice: Mean Image', ...
        substruct('.','val','{}',{1},'.','val','{}',{1}, ...
                  '.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','rmean'));
    matlabbatch{4}.spm.spatial.normalise.estwrite.subj.resample(1) = cfg_dep(...
        'Realign: Estimate & Reslice: Mean Image', ...
        substruct('.','val','{}',{1},'.','val','{}',{1}, ...
                  '.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','rmean'));
    matlabbatch{4}.spm.spatial.normalise.estwrite.subj.resample(2) = cfg_dep(...
        'Slice Timing: Slice Timing Corr. Images (Sess 1)', ...
        substruct('.','val','{}',{2},'.','val','{}',{1}, ...
                  '.','val','{}',{1}), ...
        substruct('()',{1},'.','files'));
    matlabbatch{4}.spm.spatial.normalise.estwrite.subj.resample(3) = cfg_dep(...
        'Slice Timing: Slice Timing Corr. Images (Sess 2)', ...
        substruct('.','val','{}',{2},'.','val','{}',{1}, ...
                  '.','val','{}',{1}), ...
        substruct('()',{2},'.','files'));
    matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.biasreg  = 0.0001;
    matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
    matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.tpm      = ...
        {fullfile(spm_path, 'tpm', 'TPM.nii')};
    matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.affreg   = 'mni';
    matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.reg      = ...
        [0 0.001 0.5 0.05 0.2];
    matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.fwhm     = 0;
    matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.samp     = 3;
    matlabbatch{4}.spm.spatial.normalise.estwrite.woptions.bb       = bb;
    matlabbatch{4}.spm.spatial.normalise.estwrite.woptions.vox      = vox;
    matlabbatch{4}.spm.spatial.normalise.estwrite.woptions.interp   = 4;
    matlabbatch{4}.spm.spatial.normalise.estwrite.woptions.prefix   = 'w';

    %----------------------------------------------------------------------
    % STEP 5: Normalisation — Write only (structural)
    %----------------------------------------------------------------------
    matlabbatch{5}.spm.spatial.normalise.write.subj.def(1) = cfg_dep(...
        'Normalise: Estimate & Write: Deformation (Subj 1)', ...
        substruct('.','val','{}',{4},'.','val','{}',{1}, ...
                  '.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('()',{1},'.','def'));
    matlabbatch{5}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep(...
        'Coregister: Estimate: Coregistered Images', ...
        substruct('.','val','{}',{3},'.','val','{}',{1}, ...
                  '.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('.','cfiles'));
    matlabbatch{5}.spm.spatial.normalise.write.woptions.bb     = bb;
    matlabbatch{5}.spm.spatial.normalise.write.woptions.vox    = vox;
    matlabbatch{5}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{5}.spm.spatial.normalise.write.woptions.prefix = 'w';

    %----------------------------------------------------------------------
    % STEP 6: Spatial Smoothing (6mm FWHM)
    %----------------------------------------------------------------------
    matlabbatch{6}.spm.spatial.smooth.data(1) = cfg_dep(...
        'Normalise: Estimate & Write: Normalised Images (Subj 1)', ...
        substruct('.','val','{}',{4},'.','val','{}',{1}, ...
                  '.','val','{}',{1},'.','val','{}',{1}), ...
        substruct('()',{1},'.','files'));
    matlabbatch{6}.spm.spatial.smooth.fwhm   = smooth_fwhm;
    matlabbatch{6}.spm.spatial.smooth.dtype  = 0;
    matlabbatch{6}.spm.spatial.smooth.im     = 0;
    matlabbatch{6}.spm.spatial.smooth.prefix = 's';

    %----------------------------------------------------------------------
    % RUN BATCH
    %----------------------------------------------------------------------
    spm_jobman('run', matlabbatch);
    fprintf('Completed: %s\n', bids_id);
    clear matlabbatch scans1 scans2 scans

end

fprintf('\n========================================\n');
fprintf('Preprocessing complete for all 58 subjects.\n');
fprintf('========================================\n');
