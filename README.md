# Immersive-virtual-prism-adaptation-reshapes-visual-field-representations-
Immersive virtual prism adaptation reshapes visual field representations in the inferior parietal lobule
Analysis code for:

**"Immersive virtual prism adaptation reshapes visual field representations in the inferior parietal lobule"**

Farron N, Wilf M, Perez-Marcos D, Perrin H, Serino A, Clarke S, Crottaz-Herbette S (2026)

---

## Software requirements

| Software | Version |
|----------|---------|
| MATLAB   | R2023b  |
| SPM12    | v7487   |

SPM12 is freely available at: https://www.fil.ion.ucl.ac.uk/spm/software/spm12/

---

## Data

Raw fMRI data are available on OpenNeuro:
> https://doi.org/10.18112/openneuro.dsXXXXX.v1.0.0

---

## Experimental design

58 healthy participants divided into 4 groups:

| Subjects   | Group     | Platform | Condition          |
|------------|-----------|----------|--------------------|
| sub-01–16  | iVR-shift | iVR      | Rightward shift    |
| sub-17–30  | iVR-ctrl  | iVR      | Control (no shift) |
| sub-31–44  | OD-shift  | OD       | Rightward shift    |
| sub-45–58  | OD-ctrl   | OD       | Control (no shift) |

Each participant performed a visual detection task in fMRI before
(ses-01) and after (ses-02) a brief visuomotor adaptation session.
Targets were presented in the left, central, or right visual field.

---

## Repository structure

```
VRPA-fMRI-analysis/
│
├── README.md
│
├── 01_preprocessing/
│   └── VRPA_preprocessing.m      % Full preprocessing pipeline
│
├── 02_subject_level/
│   └── VRPA_subject_level.m      % First-level GLM and contrasts
│
└── 03_group_level/
    ├── VRPA_group_level_iVR_Condition.m      % iVR-shift vs iVR-ctrl ANOVA
    └── VRPA_group_level_iVR_vs_OD_Platform.m % iVR-shift vs OD-shift ANOVA
```

---

## How to run

### Step 1 — Download the data
Download the raw fMRI data from OpenNeuro and note the folder path.

### Step 2 — Update paths
In each script, update the following variables at the top:
```matlab
base_dir = '/path/to/BIDS_dataset_final';  % OpenNeuro dataset
spm_path = '/path/to/spm12';               % SPM12 installation
stat_dir = '/path/to/derivatives';         % Output folder (subject level only)
```

### Step 3 — Run scripts in order

**Preprocessing:**
```matlab
run('01_preprocessing/VRPA_preprocessing.m')
```

**Subject-level GLM:**
```matlab
run('02_subject_level/VRPA_subject_level.m')
```

**Group-level ANOVA — iVR Condition effect (iVR-shift vs iVR-ctrl):**
```matlab
run('03_group_level/VRPA_group_level_iVR_Condition.m')
```

**Group-level ANOVA — Platform comparison (iVR-shift vs OD-shift):**
```matlab
run('03_group_level/VRPA_group_level_iVR_vs_OD_Platform.m')
```

---

## Preprocessing pipeline

Each functional run was processed in the following order:

1. **Realignment** — motion correction (Estimate & Reslice)
2. **Slice timing correction** — iVR groups: SMS multiband, 64 slices;
   OD groups: sequential ascending, 32 slices
3. **Coregistration** — structural T1w to mean functional
4. **Normalisation** — MNI space, 2×2×2mm resolution
5. **Smoothing** — 6mm FWHM Gaussian kernel

Preprocessed files carry the prefix `swar`.

---

## First-level GLM

The GLM models two sessions per subject:
- `ses-01`: Pre-adaptation fMRI
- `ses-02`: Post-adaptation fMRI

Three conditions per session:
- `StarsLeft`   — target in left visual field
- `StarsCenter` — target in central visual field
- `StarsRight`  — target in right visual field

Six motion regressors per session were included as nuisance regressors.
High-pass filter: 128s. Autocorrelation correction: AR(1).

Nine t-contrasts estimated per subject:
- Con 1–3: LEFT/CENTER/RIGHT Pre
- Con 4–6: LEFT/CENTER/RIGHT Post
- Con 7–9: Post > Pre for each visual field location

---

## MRI acquisition parameters

| Parameter          | iVR groups      | OD groups       |
|--------------------|-----------------|-----------------|
| Sequence           | SMS-EPI         | EPI             |
| TR                 | 2000 ms         | 2000 ms         |
| TE                 | 30 ms           | 30 ms           |
| Flip angle         | 80°             | 90°             |
| Slices             | 64              | 32              |
| Voxel size         | 2×2×2 mm        | 3×3×3 mm        |
| Gap                | 15%             | 10%             |
| Slice order        | Optimized SMS   | Sequential asc. |
| T1w sequence       | MP2RAGE / MPRAGE| MPRAGE          |
| T1w voxel size     | 1×1×1 mm        | 1×1×1 mm        |

---

## Contact

Nicolas Farron
nicolas.farron@chuv.ch
Service of Neuropsychology and Neurorehabilitation
Lausanne University Hospital (CHUV), Switzerland

---

## License

MIT License — see LICENSE file for details.
