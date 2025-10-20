# 🧬 LiDRoSIS
### **Lipid Droplet and ROS Segmentation and Inference System**

**LiDRoSIS** is an open-source MATLAB–Python platform for automated segmentation and quantitative analysis of **lipid droplets (LDs)** and **reactive oxygen species (ROS)** in fluorescence microscopy images of irradiated cells with or without nanoparticles.

Developed at the both **IST - Technological Nuclear Campus** and **Faculty of Sciences, University of Lisbon (FCUL)**, LiDRoSIS was created during a research internship on image-based quantification of radiation-induced cellular responses in **A549** and **MCF7** cells.  
The framework integrates **classical image processing** (MATLAB) with **statistical and visualization tools** (Python), designed for reproducibility and scalability in biomedical and radiobiology research.

---

## 🔍 **Overview**

| Module | Language | Function |
|---------|-----------|-----------|
| `mainLD_gui.m` | MATLAB | Detects and quantifies **lipid droplets** (LDs) in red and green channels |
| `mainROS_gui.m` | MATLAB | Detects and quantifies **reactive oxygen species (ROS)** fluorescence |
| `guiLD.m` / `guiROS.m` | MATLAB | Graphical user interfaces for interactive segmentation |
| `Common/` | MATLAB | Core shared functions (mask creation, intensity normalization, metrics extraction) |
| `StatLysis.py` | Python | Statistical aggregation, plotting (boxplots, ANOVA, regressions) |
| `assets/` | — | Example images and visualization resources |

---

## 🧩 **Features**

- **Automated segmentation** of LDs and ROS using intensity-based and morphological filters.  
- **Per-cell quantification** (area, intensity, circularity, colocalization).  
- **Excel data export** (`*_LDReport.xlsx` / `*_ROSReport.xlsx`) with structured sheets:  
  - `GlobalMetrics`, `NucleusMetrics`, `ObjectMetrics`.  
- **Statistical post-analysis** via Python companion script `StatLysis.py`.  
- **Batch processing** of multiple microscopy images.  
- **Reproducibility** through parameter configuration files.  

---

## ⚙️ **System Requirements**

| Component | Version / Details |
|------------|-------------------|
| MATLAB | R2022b or newer |
| Toolboxes | Image Processing Toolbox |
| Python | 3.9 or newer |
| Python Libraries | `numpy`, `pandas`, `matplotlib`, `seaborn`, `scipy`, `statsmodels` |

### Optional (for developers)
- `git` for version control  
- `Zenodo` integration for DOI generation  

---
📜 License
This project is released under the MIT License — free to use, modify, and distribute with attribution.
See the LICENSE file for details.

💬 Contact

Author: Marco António Ferreira
📧 fc60327@alunos.fc.ul.pt
🏛️ Faculty of Sciences, University of Lisbon (FCUL)

For questions or issues, please open a GitHub issue or contact the author directly.
