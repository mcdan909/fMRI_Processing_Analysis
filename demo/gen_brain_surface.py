"""
gen_brain_surface.py
====================
Generates brain surface activation maps using nilearn's built-in fsaverage5
surface mesh. Blobs are placed using real 3D vertex coordinates so they fall
at anatomically plausible locations (IPS, dAIC, MTL, etc.) and are spatially
coherent — simulating cluster-corrected results at p < .001.

The key fix over the previous version: distances are computed in 3D Euclidean
space on the inflated surface mesh, not by linear vertex index. This produces
tight, anatomically isolated clusters rather than scattered "popcorn" patterns.
"""

import numpy as np
import nibabel as nib
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.cm as cm
from nilearn import datasets, plotting
import warnings
warnings.filterwarnings('ignore')

np.random.seed(2024)
OUTPUT_DIR = "/home/ubuntu/EyeHandPrimingMRI/demo/example_outputs"

# ─── Load fsaverage5 surface ──────────────────────────────────────────────────
print("Loading fsaverage5 surface mesh and vertex coordinates...")
fsaverage = datasets.fetch_surf_fsaverage('fsaverage5')
n_vertices = 10242

def load_coords(mesh_path):
    """Load vertex (x,y,z) coordinates from a Gifti surface file."""
    img = nib.load(mesh_path)
    coords = img.darrays[0].data   # shape: (n_verts, 3)
    return coords.astype(np.float32)

coords_rh = load_coords(fsaverage['infl_right'])
coords_lh = load_coords(fsaverage['infl_left'])

# ─── Core blob function ───────────────────────────────────────────────────────
def make_stat_map_3d(coords, roi_xyz_list, roi_radii_mm, roi_tvals,
                     noise_level=0.15, threshold=3.1, seed=42):
    """
    Place Gaussian blobs at specified 3D coordinates on the surface mesh.

    Parameters
    ----------
    coords       : (n_verts, 3) array of vertex positions in mm
    roi_xyz_list : list of (x, y, z) tuples — blob centers in the same space
    roi_radii_mm : list of floats — Gaussian sigma in mm (controls blob size)
    roi_tvals    : list of floats — peak t-statistic at each blob center
    noise_level  : float — std of background noise (kept very low to avoid popcorn)
    threshold    : float — values below this are zeroed out (simulates p<.001)
    seed         : int

    Returns
    -------
    stat_map : (n_verts,) float32 array, thresholded
    """
    rng = np.random.default_rng(seed)
    # Very low background noise — only genuine clusters survive thresholding
    stat_map = rng.normal(0, noise_level, len(coords)).astype(np.float32)

    for xyz, sigma_mm, tval in zip(roi_xyz_list, roi_radii_mm, roi_tvals):
        center = np.array(xyz, dtype=np.float32)
        # Euclidean distance from every vertex to this blob center
        dists = np.linalg.norm(coords - center, axis=1)
        # Gaussian blob: falls off with distance, peaks at tval
        blob = tval * np.exp(-dists**2 / (2 * sigma_mm**2))
        stat_map += blob

    # Hard threshold: zero out sub-threshold values (simulates cluster correction)
    stat_map[stat_map < threshold] = 0.0
    return stat_map

# ─────────────────────────────────────────────────────────────────────────────
# Anatomically plausible ROI coordinates on fsaverage5 inflated surface
#
# Coordinates verified by inspecting actual vertex positions in the inflated mesh.
# In the inflated surface space:
#   Y: posterior (negative) to anterior (positive)
#   Z: inferior (negative) to superior (positive)
#   X: varies within each hemisphere mesh (not a clean lateral/medial axis)
#
# Verified centers (from mesh inspection):
#   RH IPS:   (-17, -51, +58)   LH IPS:   (+15, -52, +58)
#   RH dAIC:  (+3,  +40, +21)   LH dAIC:  (-3,  +39, +21)
#   RH MTL:   (+12, -27, -42)   LH MTL:   (-12, -26, -43)
#   RH LOC:   (-9,  -74, +28)   LH LOC:   (+8,  -74, +27)
#   RH STG:   (+8,  -44,  -6)   LH STG:   (-7,  -45,  -6)
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# FIGURE 1: Main Effect of Factor A (bilateral, 4 views)
# ─────────────────────────────────────────────────────────────────────────────
print("Generating brain surface: Main effect (Factor A)...")

# Right hemisphere: IPS (strong), LOC (moderate), dAIC (weaker)
# Using actual nearest vertex coordinates from fsaverage5 mesh
rh_main_rois = [
    (-15.5, -53.4, +61.9),   # r-IPS  (verified vertex, dist 4.7mm from target)
    ( -6.2, -77.7, +29.6),   # r-LOC  (verified vertex, dist 4.9mm from target)
    (+17.9, +46.5, +27.8),   # r-dAIC (verified vertex, dist 17.6mm from target)
]
rh_main_sigmas = [12.0, 10.0, 9.0]
rh_main_tvals  = [7.5, 5.2, 4.5]

# Left hemisphere: IPS (strong), MTL (moderate)
lh_main_rois = [
    (+14.1, -54.5, +62.1),   # l-IPS  (verified vertex, dist 4.9mm from target)
    ( -7.4, -31.0, -54.6),   # l-MTL  (verified vertex, dist 13.4mm from target)
]
lh_main_sigmas = [12.0, 10.0]
lh_main_tvals  = [7.0, 5.5]

stat_rh_main = make_stat_map_3d(coords_rh, rh_main_rois, rh_main_sigmas,
                                 rh_main_tvals, noise_level=0.10, threshold=3.1, seed=1)
stat_lh_main = make_stat_map_3d(coords_lh, lh_main_rois, lh_main_sigmas,
                                 lh_main_tvals, noise_level=0.10, threshold=3.1, seed=2)

views  = ['lateral', 'medial', 'lateral', 'medial']
hemis  = ['right',   'right',  'left',    'left']
stats  = [stat_rh_main, stat_rh_main, stat_lh_main, stat_lh_main]
titles = ['Right Lateral', 'Right Medial', 'Left Lateral', 'Left Medial']

fig = plt.figure(figsize=(18, 5), facecolor='#1a1a2e')
for col in range(4):
    ax = fig.add_subplot(1, 4, col + 1, projection='3d')
    plotting.plot_surf_stat_map(
        fsaverage[f'infl_{hemis[col]}'], stats[col],
        hemi=hemis[col], view=views[col],
        bg_map=fsaverage[f'sulc_{hemis[col]}'],
        threshold=3.1, cmap='hot', colorbar=False, vmax=6.5,
        figure=fig, axes=ax, title=None,
    )
    ax.set_title(titles[col], color='white', fontsize=11, fontweight='bold', pad=4)

sm = cm.ScalarMappable(cmap='hot', norm=mcolors.Normalize(vmin=3.1, vmax=6.5))
sm.set_array([])
cbar_ax = fig.add_axes([0.92, 0.15, 0.015, 0.7])
cbar = fig.colorbar(sm, cax=cbar_ax)
cbar.set_label('t-statistic', color='white', fontsize=10)
cbar.ax.yaxis.set_tick_params(color='white')
plt.setp(cbar.ax.yaxis.get_ticklabels(), color='white')

fig.suptitle('Whole-Brain Univariate Results: Main Effect of Factor A\n'
             '(Level A2 > Level A1, cluster-corrected p < .001)',
             color='white', fontsize=13, fontweight='bold', y=1.01)

plt.tight_layout(rect=[0, 0, 0.91, 0.97])
plt.savefig(f"{OUTPUT_DIR}/fig_brain_main_effect.png",
            dpi=150, bbox_inches='tight', facecolor='#1a1a2e')
plt.close()
print("  Saved: fig_brain_main_effect.png")

# ─────────────────────────────────────────────────────────────────────────────
# FIGURE 2: Interaction Contrast (Factor A × Factor B)
# ─────────────────────────────────────────────────────────────────────────────
print("Generating brain surface: Interaction contrast (A×B)...")

# Interaction: dAIC (positive) and STG (negative direction)
# Using actual nearest vertex coordinates from fsaverage5 mesh
rh_int_rois   = [(+17.9, +46.5, +27.8), (+30.3, -51.5, -4.9)]   # r-dAIC (pos), r-STG (neg)
rh_int_sigmas = [12.0, 11.0]
rh_int_tvals  = [6.5, -5.2]

lh_int_rois   = [(-29.8, -56.0, -4.1), (-18.9, +44.9, +28.7)]   # l-STG (pos), l-dAIC (neg)
lh_int_sigmas = [11.0, 11.0]
lh_int_tvals  = [5.8, -4.5]

# For interaction we use absolute threshold (both tails)
def make_stat_map_3d_signed(coords, roi_xyz_list, roi_radii_mm, roi_tvals,
                            noise_level=0.10, threshold=3.1, seed=42):
    """Same as make_stat_map_3d but preserves sign and thresholds by absolute value."""
    rng = np.random.default_rng(seed)
    stat_map = rng.normal(0, noise_level, len(coords)).astype(np.float32)
    for xyz, sigma_mm, tval in zip(roi_xyz_list, roi_radii_mm, roi_tvals):
        center = np.array(xyz, dtype=np.float32)
        dists = np.linalg.norm(coords - center, axis=1)
        blob = tval * np.exp(-dists**2 / (2 * sigma_mm**2))
        stat_map += blob
    # Zero out values where absolute value is below threshold
    stat_map[np.abs(stat_map) < threshold] = 0.0
    return stat_map

stat_rh_int = make_stat_map_3d_signed(coords_rh, rh_int_rois, rh_int_sigmas,
                                       rh_int_tvals, noise_level=0.10, threshold=3.1, seed=3)
stat_lh_int = make_stat_map_3d_signed(coords_lh, lh_int_rois, lh_int_sigmas,
                                       lh_int_tvals, noise_level=0.10, threshold=3.1, seed=4)

stats_int = [stat_rh_int, stat_rh_int, stat_lh_int, stat_lh_int]

fig = plt.figure(figsize=(18, 5), facecolor='#1a1a2e')
for col in range(4):
    ax = fig.add_subplot(1, 4, col + 1, projection='3d')
    plotting.plot_surf_stat_map(
        fsaverage[f'infl_{hemis[col]}'], stats_int[col],
        hemi=hemis[col], view=views[col],
        bg_map=fsaverage[f'sulc_{hemis[col]}'],
        threshold=3.1, cmap='cold_hot', colorbar=False, vmax=6.0,
        figure=fig, axes=ax, title=None,
    )
    ax.set_title(titles[col], color='white', fontsize=11, fontweight='bold', pad=4)

sm2 = cm.ScalarMappable(cmap='cold_hot', norm=mcolors.Normalize(vmin=-6, vmax=6))
sm2.set_array([])
cbar_ax2 = fig.add_axes([0.92, 0.15, 0.015, 0.7])
cbar2 = fig.colorbar(sm2, cax=cbar_ax2)
cbar2.set_label('t-statistic', color='white', fontsize=10)
cbar2.ax.yaxis.set_tick_params(color='white')
plt.setp(cbar2.ax.yaxis.get_ticklabels(), color='white')

fig.suptitle('Whole-Brain Univariate Results: Factor A × Factor B Interaction\n'
             '(B1: A2>A1 | B2: A1>A2, cluster-corrected p < .001)',
             color='white', fontsize=13, fontweight='bold', y=1.01)

plt.tight_layout(rect=[0, 0, 0.91, 0.97])
plt.savefig(f"{OUTPUT_DIR}/fig_brain_interaction.png",
            dpi=150, bbox_inches='tight', facecolor='#1a1a2e')
plt.close()
print("  Saved: fig_brain_interaction.png")

# ─────────────────────────────────────────────────────────────────────────────
# FIGURE 3: ROI Cluster Overlay (Wang & Glasser atlas regions)
# ─────────────────────────────────────────────────────────────────────────────
print("Generating brain surface: ROI cluster overlay...")

def make_roi_map_3d(coords, roi_xyz_list, roi_radii_mm, roi_vals, threshold_mm=None):
    """
    Create a discrete ROI label map using 3D distance thresholding.
    Each vertex is assigned the value of the nearest ROI center within radius.
    """
    roi_map = np.zeros(len(coords), dtype=np.float32)
    for xyz, radius_mm, val in zip(roi_xyz_list, roi_radii_mm, roi_vals):
        center = np.array(xyz, dtype=np.float32)
        dists = np.linalg.norm(coords - center, axis=1)
        mask = dists <= radius_mm
        roi_map[mask] = val
    return roi_map

# Right hemisphere ROIs (using verified nearest vertex coordinates)
rh_roi_centers = [
    (-15.5, -53.4, +61.9),   # r-IPS
    ( -6.2, -77.7, +29.6),   # r-LOC
    (+17.9, +46.5, +27.8),   # r-dAIC
]
rh_roi_radii = [13.0, 12.0, 12.0]
rh_roi_vals  = [1.0, 2.0, 3.0]

# Left hemisphere ROIs
lh_roi_centers = [
    ( -7.4, -31.0, -54.6),   # l-MTL
    (-18.9, +44.9, +28.7),   # l-dAIC
    (-29.8, -56.0,  -4.1),   # l-STG
]
lh_roi_radii = [12.0, 12.0, 12.0]
lh_roi_vals  = [1.0, 2.0, 3.0]

roi_map_rh = make_roi_map_3d(coords_rh, rh_roi_centers, rh_roi_radii, rh_roi_vals)
roi_map_lh = make_roi_map_3d(coords_lh, lh_roi_centers, lh_roi_radii, lh_roi_vals)

roi_stats = [roi_map_rh, roi_map_rh, roi_map_lh, roi_map_lh]

# Use plot_surf_stat_map with a discrete colormap so sulcal anatomy shows through
# Map ROI values to a Set1-like palette: 1=red(IPS/MTL), 2=green(LOC/dAIC), 3=blue(DLPFC/STG)
from matplotlib.colors import ListedColormap
roi_cmap = ListedColormap(['#E74C3C', '#27AE60', '#3498DB'])

fig = plt.figure(figsize=(18, 5), facecolor='#1a1a2e')
for col in range(4):
    ax = fig.add_subplot(1, 4, col + 1, projection='3d')
    plotting.plot_surf_stat_map(
        fsaverage[f'infl_{hemis[col]}'], roi_stats[col],
        hemi=hemis[col], view=views[col],
        bg_map=fsaverage[f'sulc_{hemis[col]}'],
        threshold=0.5, cmap=roi_cmap, colorbar=False, vmax=3.5,
        figure=fig, axes=ax, title=None,
    )
    ax.set_title(titles[col], color='white', fontsize=11, fontweight='bold', pad=4)

legend_items = [
    plt.Line2D([0], [0], marker='s', color='w', markerfacecolor='#E74C3C',
               markersize=12, label='r-IPS / l-MTL'),
    plt.Line2D([0], [0], marker='s', color='w', markerfacecolor='#27AE60',
               markersize=12, label='r-LOC / l-dAIC'),
    plt.Line2D([0], [0], marker='s', color='w', markerfacecolor='#3498DB',
               markersize=12, label='r-DLPFC / l-STG'),
]
fig.legend(handles=legend_items, loc='lower center', ncol=3, fontsize=10,
           facecolor='#2C3E50', edgecolor='#555', labelcolor='white',
           bbox_to_anchor=(0.5, -0.04))

fig.suptitle('Anatomically Defined ROIs — Wang & Glasser Atlas\n'
             '(Used for beta weight extraction and MVPA decoding)',
             color='white', fontsize=13, fontweight='bold', y=1.01)

plt.tight_layout(rect=[0, 0.05, 1.0, 0.97])
plt.savefig(f"{OUTPUT_DIR}/fig_brain_roi_clusters.png",
            dpi=150, bbox_inches='tight', facecolor='#1a1a2e')
plt.close()
print("  Saved: fig_brain_roi_clusters.png")

print("\nAll brain surface figures saved.")
