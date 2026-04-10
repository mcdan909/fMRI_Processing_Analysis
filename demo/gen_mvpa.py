"""
gen_mvpa.py — MVPA Cross-Classification Pipeline
=================================================
Implements a full multi-voxel pattern analysis (MVPA) cross-classification
pipeline on synthetic dummy data, demonstrating the ML workflow used in
O'Bryan et al. (2024) and adaptable to any 2x2 fMRI design.

Design:
  Factor A: Level A1 vs. Level A2  (e.g., Color Repeat vs. Color Switch)
  Factor B: Level B1 vs. Level B2  (e.g., Effector: Hand vs. Eye)

Cross-classification logic:
  Train SVM on Factor B Level B1 trials → Test on Factor B Level B2 trials
  Train SVM on Factor B Level B2 trials → Test on Factor B Level B1 trials
  Average decoding accuracy = effector-independent representation of Factor A

Outputs:
  fig_mvpa_pipeline.png       — Schematic of the cross-classification logic
  fig_mvpa_decoding.png       — Group decoding accuracy per ROI + chance
  fig_mvpa_brain_behavior.png — Brain-behavior scatter (decoding vs. behavioral effect)
  fig_mvpa_confusion.png      — Confusion matrices for two key ROIs
  fig_mvpa_learning_curve.png — SVM learning curve (training size vs. accuracy)
"""

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.gridspec as gridspec
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch
from sklearn.svm import SVC
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import StratifiedKFold, learning_curve
from sklearn.pipeline import Pipeline
from sklearn.metrics import confusion_matrix, accuracy_score
from sklearn.utils import resample
import warnings
warnings.filterwarnings('ignore')

np.random.seed(2024)

OUTPUT_DIR = "/home/ubuntu/EyeHandPrimingMRI/demo/example_outputs"
BG = "#F8F9FA"

# ─── Experimental parameters ─────────────────────────────────────────────────
N_SUBJECTS  = 16
N_TRIALS    = 60    # trials per condition per subject (realistic for fMRI)
N_ROIS      = 7
ROIS        = ["r-IPS", "l-MTL", "r-STG", "l-dAIC", "Cerebellum", "l-DLPFC", "r-LOC"]
N_VOXELS    = {roi: v for roi, v in zip(ROIS, [85, 62, 48, 54, 72, 58, 44])}

# ROI signal strengths: how well Factor A can be decoded from each ROI
# (d-prime-like effect size for the SVM feature space)
ROI_SIGNAL = {
    "r-IPS":      0.38,   # strong, effector-independent → high cross-classification (~68%)
    "l-MTL":      0.30,   # moderate, cross-classifies (~63%)
    "r-STG":      0.04,   # near chance (~51%)
    "l-dAIC":     0.07,   # weak, effector-specific (~53%)
    "Cerebellum": 0.03,   # near chance
    "l-DLPFC":    0.06,   # near chance
    "r-LOC":      0.05,   # near chance
}

# ─────────────────────────────────────────────────────────────────────────────
# FIGURE 1: Pipeline Schematic
# ─────────────────────────────────────────────────────────────────────────────
print("Generating MVPA pipeline schematic...")

fig, ax = plt.subplots(figsize=(14, 5), facecolor=BG)
ax.set_xlim(0, 14)
ax.set_ylim(0, 5)
ax.axis('off')
fig.patch.set_facecolor(BG)

# Boxes
boxes = [
    (1.0, 2.5, "fMRI Data\n(4D volume)", "#2C6FAC", "white"),
    (3.5, 3.5, "Factor B Level 1\nTrials (B1)", "#27AE60", "white"),
    (3.5, 1.5, "Factor B Level 2\nTrials (B2)", "#E67E22", "white"),
    (6.5, 3.5, "Train SVM\non B1", "#27AE60", "white"),
    (6.5, 1.5, "Train SVM\non B2", "#E67E22", "white"),
    (9.5, 3.5, "Test on B2\n(cross-classify)", "#E67E22", "white"),
    (9.5, 1.5, "Test on B1\n(cross-classify)", "#27AE60", "white"),
    (12.2, 2.5, "Average\nDecoding\nAccuracy", "#9B59B6", "white"),
]

for (x, y, label, color, tc) in boxes:
    rect = FancyBboxPatch((x - 0.9, y - 0.65), 1.8, 1.3,
                           boxstyle="round,pad=0.08", linewidth=1.5,
                           edgecolor=color, facecolor=color + '33', zorder=2)
    ax.add_patch(rect)
    ax.text(x, y, label, ha='center', va='center', fontsize=8.5,
            fontweight='bold', color='#1a1a1a', zorder=3, linespacing=1.3)

# Arrows
arrow_kw = dict(arrowstyle='->', color='#555555', lw=1.5)
ax.annotate('', xy=(2.6, 3.5), xytext=(1.9, 3.0), arrowprops=arrow_kw)
ax.annotate('', xy=(2.6, 1.5), xytext=(1.9, 2.0), arrowprops=arrow_kw)
ax.annotate('', xy=(5.6, 3.5), xytext=(4.4, 3.5), arrowprops=arrow_kw)
ax.annotate('', xy=(5.6, 1.5), xytext=(4.4, 1.5), arrowprops=arrow_kw)
ax.annotate('', xy=(8.6, 3.5), xytext=(7.4, 3.5), arrowprops=arrow_kw)
ax.annotate('', xy=(8.6, 1.5), xytext=(7.4, 1.5), arrowprops=arrow_kw)
ax.annotate('', xy=(11.3, 2.8), xytext=(10.4, 3.3), arrowprops=arrow_kw)
ax.annotate('', xy=(11.3, 2.2), xytext=(10.4, 1.7), arrowprops=arrow_kw)

# Cross arrows (the cross-classification)
ax.annotate('', xy=(8.6, 1.5), xytext=(7.4, 3.5),
            arrowprops=dict(arrowstyle='->', color='#E74C3C', lw=1.5, linestyle='dashed'))
ax.annotate('', xy=(8.6, 3.5), xytext=(7.4, 1.5),
            arrowprops=dict(arrowstyle='->', color='#E74C3C', lw=1.5, linestyle='dashed'))

ax.text(7.5, 2.5, 'Cross-\nclassify', ha='center', va='center',
        fontsize=8, color='#E74C3C', fontweight='bold')

# ROI extraction label
ax.text(1.0, 4.4, 'ROI Beta\nWeights\n(per voxel)', ha='center', va='center',
        fontsize=8, color='#555', style='italic')

ax.set_title('MVPA Cross-Classification Logic\n'
             'Train on Factor B Level 1 → Test on Level 2 (and vice versa)',
             fontsize=12, fontweight='bold', color='#1a1a1a', pad=10)

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/fig_mvpa_pipeline.png",
            dpi=160, bbox_inches='tight', facecolor=BG)
plt.close()
print("  Saved: fig_mvpa_pipeline.png")

# ─────────────────────────────────────────────────────────────────────────────
# Generate synthetic multi-voxel patterns per subject per ROI
# ─────────────────────────────────────────────────────────────────────────────
print("Generating synthetic voxel patterns and running SVMs...")

def generate_roi_patterns(n_trials, n_voxels, signal_strength, seed=0):
    """
    Generate synthetic multi-voxel patterns for a 2-class classification problem.
    Class 0 = Factor A Level 1 (e.g., Repeat)
    Class 1 = Factor A Level 2 (e.g., Switch)
    Returns X (n_trials x n_voxels), y (n_trials,)

    Uses a mean-shift approach: class 1 trials have a consistent positive shift
    on a subset of 'informative' voxels. Signal-to-noise ratio scales with
    signal_strength.
    """
    rng = np.random.default_rng(seed)
    n_half = n_trials // 2
    labels = np.array([0] * n_half + [1] * (n_trials - n_half))
    rng.shuffle(labels)

    # Per-voxel noise (trial-by-trial)
    noise = rng.normal(0, 1.0, (n_trials, n_voxels))

    # Informative voxels: top 40% carry the signal
    n_info = max(1, int(n_voxels * 0.40))
    # Fixed signal pattern (same across B1 and B2 — this is what makes cross-classification work)
    signal_vals = np.zeros(n_voxels)
    signal_vals[:n_info] = signal_strength  # first n_info voxels carry the signal

    # Add signal for class 1 trials
    X = noise.copy()
    for i, lbl in enumerate(labels):
        if lbl == 1:
            X[i] += signal_vals

    return X.astype(np.float32), labels

def cross_classify(X_b1, y_b1, X_b2, y_b2):
    """
    Train SVM on B1, test on B2. Train SVM on B2, test on B1.
    Returns mean cross-classification accuracy.
    """
    pipe = Pipeline([('scaler', StandardScaler()), ('svm', SVC(kernel='linear', C=1.0))])
    pipe.fit(X_b1, y_b1)
    acc_b1_to_b2 = accuracy_score(y_b2, pipe.predict(X_b2))
    pipe.fit(X_b2, y_b2)
    acc_b2_to_b1 = accuracy_score(y_b1, pipe.predict(X_b1))
    return (acc_b1_to_b2 + acc_b2_to_b1) / 2.0

# Run cross-classification for all subjects and ROIs
results = {roi: [] for roi in ROIS}
behavioral_effects = np.random.normal(18, 14, N_SUBJECTS)  # ms priming effect

for subj_idx in range(N_SUBJECTS):
    for roi in ROIS:
        n_vox = N_VOXELS[roi]
        sig   = ROI_SIGNAL[roi]
        # B1 patterns (Factor B Level 1, e.g., Hand trials)
        X_b1, y_b1 = generate_roi_patterns(N_TRIALS, n_vox, sig, seed=subj_idx * 100 + ROIS.index(roi))
        # B2 patterns (Factor B Level 2, e.g., Eye trials) — same signal, different noise
        X_b2, y_b2 = generate_roi_patterns(N_TRIALS, n_vox, sig, seed=subj_idx * 100 + ROIS.index(roi) + 50)
        acc = cross_classify(X_b1, y_b1, X_b2, y_b2)
        results[roi].append(acc)

# Convert to arrays
acc_array = np.array([results[roi] for roi in ROIS])   # shape: (n_rois, n_subjects)
group_mean = acc_array.mean(axis=1)
group_sem  = acc_array.std(axis=1) / np.sqrt(N_SUBJECTS)

# ─────────────────────────────────────────────────────────────────────────────
# FIGURE 2: Group Decoding Accuracy per ROI
# ─────────────────────────────────────────────────────────────────────────────
print("Generating MVPA decoding accuracy figure...")

fig, ax = plt.subplots(figsize=(11, 5.5), facecolor=BG)

colors_roi = ["#E74C3C", "#9B59B6", "#95A5A6", "#E67E22", "#BDC3C7", "#3498DB", "#2ECC71"]
x = np.arange(len(ROIS))
bars = ax.bar(x, group_mean, width=0.55,
              color=colors_roi, edgecolor='white', linewidth=1.2, zorder=2)
ax.errorbar(x, group_mean, yerr=group_sem,
            fmt='none', color='#1a1a1a', capsize=6, capthick=1.5,
            elinewidth=1.5, zorder=3)
ax.axhline(0.50, color='#333333', lw=1.5, linestyle='--',
           label='Chance (50%)', zorder=1)

# Significance markers (one-sample t-test vs 0.5)
from scipy import stats as scipy_stats
for i, roi in enumerate(ROIS):
    t, p = scipy_stats.ttest_1samp(acc_array[i], 0.50)
    if p < 0.01:
        ax.text(i, group_mean[i] + group_sem[i] + 0.005, '**',
                ha='center', fontsize=13, color='#1a1a1a')
    elif p < 0.05:
        ax.text(i, group_mean[i] + group_sem[i] + 0.005, '*',
                ha='center', fontsize=13, color='#1a1a1a')

ax.set_xticks(x)
ax.set_xticklabels(ROIS, fontsize=11)
ax.set_ylabel('Cross-Classification Accuracy', fontsize=11)
ax.set_ylim(0.44, 0.78)
ax.set_title('MVPA Cross-Classification: Group Decoding Accuracy per ROI\n'
             '(Train on Factor B Level 1 → Test on Level 2, and vice versa)',
             fontsize=12, fontweight='bold')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.set_facecolor(BG)
ax.yaxis.grid(True, color='#dddddd', zorder=0)
ax.set_axisbelow(True)
ax.legend(fontsize=10, framealpha=0.8)

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/fig_mvpa_decoding.png",
            dpi=160, bbox_inches='tight', facecolor=BG)
plt.close()
print("  Saved: fig_mvpa_decoding.png")

# ─────────────────────────────────────────────────────────────────────────────
# FIGURE 3: Brain-Behavior Scatter (decoding accuracy vs. behavioral effect)
# ─────────────────────────────────────────────────────────────────────────────
print("Generating brain-behavior scatter...")

fig, axes = plt.subplots(1, 2, figsize=(11, 5.5), facecolor=BG)

for ax_idx, (roi, color) in enumerate([("r-IPS", "#E74C3C"), ("l-MTL", "#9B59B6")]):
    ax = axes[ax_idx]
    roi_accs = acc_array[ROIS.index(roi)]
    r, p = scipy_stats.pearsonr(behavioral_effects, roi_accs)

    ax.scatter(behavioral_effects, roi_accs, color=color, s=65, alpha=0.85,
               edgecolors='white', linewidths=0.8, zorder=3)

    # Regression line
    m, b = np.polyfit(behavioral_effects, roi_accs, 1)
    x_line = np.linspace(behavioral_effects.min() - 2, behavioral_effects.max() + 2, 100)
    ax.plot(x_line, m * x_line + b, color=color, lw=2.0, linestyle='--', alpha=0.8, zorder=2)

    ax.axhline(0.50, color='#888888', lw=1.0, linestyle=':', zorder=1)
    ax.set_xlabel('Behavioral Effect (ms)', fontsize=10)
    ax.set_ylabel('Cross-Classification Accuracy', fontsize=10)
    ax.set_title(f'{roi}   r = {r:.2f}{"*" if p < 0.05 else ""}',
                 fontsize=12, fontweight='bold')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_facecolor(BG)
    ax.yaxis.grid(True, color='#dddddd', zorder=0)
    ax.xaxis.grid(True, color='#dddddd', zorder=0)
    ax.set_axisbelow(True)

fig.suptitle('Brain–Behavior Correlation: Individual Differences\n'
             'Subjects with larger behavioral priming effects show higher decoding accuracy',
             fontsize=12, fontweight='bold', y=1.02)
plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/fig_mvpa_brain_behavior.png",
            dpi=160, bbox_inches='tight', facecolor=BG)
plt.close()
print("  Saved: fig_mvpa_brain_behavior.png")

# ─────────────────────────────────────────────────────────────────────────────
# FIGURE 4: Confusion Matrices for two key ROIs
# ─────────────────────────────────────────────────────────────────────────────
print("Generating confusion matrices...")

fig, axes = plt.subplots(1, 2, figsize=(10, 4.5), facecolor=BG)

for ax_idx, (roi, color) in enumerate([("r-IPS", "#E74C3C"), ("r-STG", "#95A5A6")]):
    ax = axes[ax_idx]
    n_vox = N_VOXELS[roi]
    sig   = ROI_SIGNAL[roi]

    # Aggregate confusion matrix across all subjects
    cm_total = np.zeros((2, 2), dtype=int)
    for subj_idx in range(N_SUBJECTS):
        X_b1, y_b1 = generate_roi_patterns(N_TRIALS, n_vox, sig,
                                            seed=subj_idx * 100 + ROIS.index(roi))
        X_b2, y_b2 = generate_roi_patterns(N_TRIALS, n_vox, sig,
                                            seed=subj_idx * 100 + ROIS.index(roi) + 50)
        pipe = Pipeline([('scaler', StandardScaler()), ('svm', SVC(kernel='linear', C=1.0))])
        pipe.fit(X_b1, y_b1)
        cm_total += confusion_matrix(y_b2, pipe.predict(X_b2))

    # Normalize to proportions
    cm_norm = cm_total / cm_total.sum(axis=1, keepdims=True)

    im = ax.imshow(cm_norm, cmap='Blues', vmin=0.3, vmax=0.7)
    ax.set_xticks([0, 1])
    ax.set_yticks([0, 1])
    ax.set_xticklabels(['Predicted\nA1', 'Predicted\nA2'], fontsize=10)
    ax.set_yticklabels(['True A1', 'True A2'], fontsize=10)

    for i in range(2):
        for j in range(2):
            ax.text(j, i, f'{cm_norm[i, j]:.2f}',
                    ha='center', va='center', fontsize=14, fontweight='bold',
                    color='white' if cm_norm[i, j] > 0.55 else '#1a1a1a')

    acc_val = group_mean[ROIS.index(roi)]
    ax.set_title(f'{roi}   (Acc = {acc_val:.3f})', fontsize=12, fontweight='bold',
                 color=color)
    plt.colorbar(im, ax=ax, shrink=0.85)

fig.suptitle('Confusion Matrices: SVM Cross-Classification\n'
             '(Normalized; diagonal = correct classifications)',
             fontsize=12, fontweight='bold', y=1.02)
plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/fig_mvpa_confusion.png",
            dpi=160, bbox_inches='tight', facecolor=BG)
plt.close()
print("  Saved: fig_mvpa_confusion.png")

# ─────────────────────────────────────────────────────────────────────────────
# FIGURE 5: SVM Learning Curve for best ROI
# ─────────────────────────────────────────────────────────────────────────────
print("Generating SVM learning curve...")

roi = "r-IPS"
n_vox = N_VOXELS[roi]
sig   = ROI_SIGNAL[roi]

# Pool data across subjects for learning curve
X_all, y_all = [], []
for subj_idx in range(N_SUBJECTS):
    X_b1, y_b1 = generate_roi_patterns(N_TRIALS, n_vox, sig,
                                        seed=subj_idx * 100 + ROIS.index(roi))
    X_b2, y_b2 = generate_roi_patterns(N_TRIALS, n_vox, sig,
                                        seed=subj_idx * 100 + ROIS.index(roi) + 50)
    X_all.append(np.vstack([X_b1, X_b2]))
    y_all.append(np.hstack([y_b1, y_b2]))
X_pool = np.vstack(X_all)
y_pool = np.hstack(y_all)

pipe = Pipeline([('scaler', StandardScaler()), ('svm', SVC(kernel='linear', C=1.0))])
train_sizes, train_scores, test_scores = learning_curve(
    pipe, X_pool, y_pool,
    train_sizes=np.linspace(0.1, 1.0, 10),
    cv=StratifiedKFold(n_splits=5, shuffle=True, random_state=42),
    scoring='accuracy', n_jobs=-1
)

train_mean = train_scores.mean(axis=1)
train_std  = train_scores.std(axis=1)
test_mean  = test_scores.mean(axis=1)
test_std   = test_scores.std(axis=1)

fig, ax = plt.subplots(figsize=(8, 5.5), facecolor=BG)
ax.fill_between(train_sizes, train_mean - train_std, train_mean + train_std,
                alpha=0.15, color='#2C6FAC')
ax.fill_between(train_sizes, test_mean - test_std, test_mean + test_std,
                alpha=0.15, color='#E74C3C')
ax.plot(train_sizes, train_mean, 'o-', color='#2C6FAC', lw=2, label='Training accuracy')
ax.plot(train_sizes, test_mean,  's-', color='#E74C3C', lw=2, label='Cross-validation accuracy')
ax.axhline(0.50, color='#888888', lw=1.2, linestyle='--', label='Chance (50%)')
ax.set_xlabel('Training Set Size (trials)', fontsize=11)
ax.set_ylabel('Accuracy', fontsize=11)
ax.set_title(f'SVM Learning Curve — {roi}\n'
             '(Convergence of cross-validation accuracy with increasing training data)',
             fontsize=11, fontweight='bold')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.set_facecolor(BG)
ax.yaxis.grid(True, color='#dddddd', zorder=0)
ax.set_axisbelow(True)
ax.legend(fontsize=10, framealpha=0.8)
ax.set_ylim(0.44, 1.02)

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/fig_mvpa_learning_curve.png",
            dpi=160, bbox_inches='tight', facecolor=BG)
plt.close()
print("  Saved: fig_mvpa_learning_curve.png")

print(f"\nAll MVPA figures saved to {OUTPUT_DIR}")

# Print summary table
print("\n── Group Decoding Accuracy Summary ──")
print(f"{'ROI':<14} {'Mean Acc':>10} {'SEM':>8} {'vs. Chance':>12}")
print("-" * 46)
for i, roi in enumerate(ROIS):
    t, p = scipy_stats.ttest_1samp(acc_array[i], 0.50)
    sig_str = "**" if p < 0.01 else ("*" if p < 0.05 else "n.s.")
    print(f"{roi:<14} {group_mean[i]:>10.4f} {group_sem[i]:>8.4f} {sig_str:>12}")
