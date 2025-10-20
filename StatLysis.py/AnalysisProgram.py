import os
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from scipy import stats
from statsmodels.formula.api import ols
import statsmodels.api as sm
from statsmodels.stats.multicomp import pairwise_tukeyhsd
from sklearn.metrics import r2_score
from scipy.optimize import curve_fit
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import warnings

# Suppress rank warning from polyfit
import warnings

# Suprimir o aviso de ajuste mal condicionado do polyfit
warnings.filterwarnings("ignore", category=UserWarning, message=".*Polyfit may be poorly conditioned.*")


# ========== 📁 DATA LOADING ==========

def parse_metadata_from_filename(filename):
    parts = os.path.splitext(filename)[0].split('_')
    try:
        return {
            'CellLine': parts[1],
            'Radiation': parts[2],
            'NP': parts[3],
            'Dose': parts[4].replace("Gy", "").strip()
        }
    except IndexError:
        return {k: 'Unknown' for k in ['CellLine', 'Radiation', 'NP', 'Dose']}

def read_aggregated_excel(filepath):
    metadata = parse_metadata_from_filename(os.path.basename(filepath))
    try:
        xls = pd.ExcelFile(filepath)
        df = pd.read_excel(xls, sheet_name=xls.sheet_names[0])
        for k, v in metadata.items():
            df[k] = v
        for col in df.select_dtypes(include='object'):
            if df[col].str.contains(',', regex=False).any():
                try:
                    df[col] = df[col].str.replace(',', '.').astype(float)
                except:
                    pass
        return df
    except Exception as e:
        messagebox.showerror("Read Error", f"{filepath}:\n{e}")
        return pd.DataFrame()

def load_all_aggregated_data(folder):
    dfs = []
    for fname in os.listdir(folder):
        if fname.endswith('.xlsx') and fname.startswith('Aggregated_'):
            df = read_aggregated_excel(os.path.join(folder, fname))
            if not df.empty:
                dfs.append(df)
    return pd.concat(dfs, ignore_index=True) if dfs else pd.DataFrame()

# ========== 🔄 PREPROCESSING ==========

def remove_outliers(df, response_var, z_thresh=3):
    z = np.abs(stats.zscore(df[response_var], nan_policy='omit'))
    return df[z < z_thresh], int((z >= z_thresh).sum())

def apply_normalization(df, response_var, method):
    if method == 'log1p':
        df[response_var] = np.log1p(df[response_var])
    elif method == 'zscore':
        df[response_var] = (df[response_var] - df[response_var].mean()) / df[response_var].std()
    elif method == 'minmax':
        df[response_var] = (df[response_var] - df[response_var].min()) / (df[response_var].max() - df[response_var].min())
    return df

def create_derived_vars(df):
    if 'NumROS' in df.columns and 'NumNuclei' in df.columns:
        df['ROS_per_Nucleus'] = df['NumROS'] / df['NumNuclei']
    if 'TotalROSFluorescence' in df.columns and 'NumNuclei' in df.columns:
        df['Fluo_per_Nucleus'] = df['TotalROSFluorescence'] / df['NumNuclei']
    if 'TotalROSArea' in df.columns and 'NumROS' in df.columns:
        df['Area_per_ROS'] = df['TotalROSArea'] / df['NumROS']
    if 'TotalLDAreaRed' in df.columns and 'NumNuclei' in df.columns:
        df['LDAreaRed_per_Nucleus'] = df['TotalLDAreaRed'] / df['NumNuclei']
    return df

# ========== 📊 STATISTICAL ANALYSIS ==========

def perform_anova(df, response_var, factors):
    formula = f"{response_var} ~ " + ' + '.join([f'C({f})' for f in factors]) + ' + ' + ':'.join([f'C({f})' for f in factors])
    model = ols(formula, data=df).fit()
    anova = sm.stats.anova_lm(model, typ=2)
    anova['eta_sq'] = anova['sum_sq'] / (anova['sum_sq'].sum() + model.ssr)
    return model, anova

def run_tukey(df, response_var, factor):
    if df[factor].nunique() < 2:
        return f"Tukey HSD skipped: only one group in '{factor}'"
    tukey = pairwise_tukeyhsd(df[response_var], df[factor])
    return tukey.summary().as_text(), tukey._results_table.data

def run_regression(df, response_var, num_var, cat_var):
    formula = f"{response_var} ~ {num_var} * C({cat_var})"
    model = ols(formula, data=df).fit()
    return model, model.summary().as_text()

# ========== 📁 OUTPUT FOLDER CREATION ==========

def make_output_dir(cellline, radiation, np_status):
    base_dir = os.path.join(os.path.dirname(__file__), "Análise")
    os.makedirs(base_dir, exist_ok=True)
    group_name = f"{cellline}_{radiation}_{np_status}".replace(" ", "_")
    output_dir = os.path.join(base_dir, group_name)
    os.makedirs(output_dir, exist_ok=True)
    return output_dir

# ========== 🧠 AI-LIKE INTERPRETATION ==========

def generate_conclusion(model, response_var, cat_factor):
    r2 = model.rsquared
    strength = (
        "weak" if r2 < 0.2 else
        "moderate" if r2 < 0.5 else
        "strong"
    )
    coef_dose = model.params.get('Dose_numeric', 0)
    direction = "increase" if coef_dose > 0 else "decrease" if coef_dose < 0 else "remain constant"
    p_value = model.pvalues.get('Dose_numeric', 1)
    sig = "significant" if p_value < 0.05 else "not significant"

    conclusion = (
        f"Based on an R² of {r2:.2f}, there is a {strength} association between '{response_var}' "
        f"and the dose. The coefficient suggests the response tends to {direction} as the dose increases. "
        f"This effect was {sig} (p = {p_value:.4f})."
    )

    for term in model.params.index:
        if "Dose_numeric:C(" in term and model.pvalues[term] < 0.05:
            factor_name = term.split(":")[1].split("[")[0].replace("C(", "").replace(")", "")
            level = term.split("[T.")[1].split("]")[0]
            conclusion += f" There is also evidence that dose effect differs for group '{level}' of factor '{factor_name}'."

    return conclusion

# ========== 📈 REGRESSION COMPARISON PLOT ==========

def plot_regression_models(df, x, y, save_path=None):
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.scatter(df[x], df[y], alpha=0.6, label='Data')

    models = {}
    x_vals = np.linspace(df[x].min(), df[x].max(), 200)

    # Linear
    lin = np.polyfit(df[x], df[y], 1)
    models['Linear'] = (x_vals, np.polyval(lin, x_vals))

    # Poly2
    poly2 = np.polyfit(df[x], df[y], 2)
    models['Poly2'] = (x_vals, np.polyval(poly2, x_vals))

    # Poly3
    poly3 = np.polyfit(df[x], df[y], 3)
    models['Poly3'] = (x_vals, np.polyval(poly3, x_vals))

    # Exponential (fit only on positive y)
    try:
        df_exp = df[df[y] > 0]
        popt, _ = curve_fit(lambda x, a, b: a * np.exp(b * x), df_exp[x], df_exp[y], maxfev=10000)
        models['Exponential'] = (x_vals, popt[0] * np.exp(popt[1] * x_vals))
    except Exception:
        pass

    # Logarithmic (fit on x > 0)
    try:
        df_log = df[df[x] > 0]
        popt, _ = curve_fit(lambda x, a, b: a + b * np.log(x), df_log[x], df_log[y])
        models['Logarithmic'] = (x_vals, popt[0] + popt[1] * np.log(x_vals))
    except Exception:
        pass

    # Log-Linear (log(y) = a + b * x)
    try:
        df_loglin = df[df[y] > 0]
        log_y = np.log(df_loglin[y])
        linfit = np.polyfit(df_loglin[x], log_y, 1)
        models['Log-Linear'] = (x_vals, np.exp(linfit[1] + linfit[0] * x_vals))
    except Exception:
        pass

    # Plot all models
    for name, (x_, y_) in models.items():
        ax.plot(x_, y_, label=name)

    ax.legend()
    ax.set_title(f"Regression Fits: {y} vs {x}")
    ax.set_xlabel(x)
    ax.set_ylabel(y)
    fig.tight_layout()

    if save_path:
        fig.savefig(save_path, dpi=300)

    return fig

class AnalyzerApp:
    def __init__(self, master):
        self.master = master
        master.title("📊 Experimental Analyzer")
        master.state("zoomed")

        self.df = pd.DataFrame()

        # ==== Layout ====
        main = tk.PanedWindow(master, orient=tk.HORIZONTAL)
        main.pack(fill=tk.BOTH, expand=True)

        left = tk.Frame(main)
        right = tk.Frame(main, bg="white")
        main.add(left, width=480)
        main.add(right)

        # ==== Control Panel ====
        control = tk.LabelFrame(left, text="⚙️ Options")
        control.pack(fill=tk.X, padx=8, pady=5)

        tk.Button(control, text="📁 Load Folder", command=self.load_folder).grid(row=0, column=0)
        tk.Label(control, text="Response:").grid(row=0, column=1)
        self.response_combo = ttk.Combobox(control, width=28, state="readonly")
        self.response_combo.grid(row=0, column=2, columnspan=2)

        tk.Label(control, text="CellLine:").grid(row=1, column=0)
        self.cellline_combo = ttk.Combobox(control, width=20, state="readonly")
        self.cellline_combo.grid(row=1, column=1)
        self.cellline_combo.bind("<<ComboboxSelected>>", self.update_np_options)

        tk.Label(control, text="NP:").grid(row=1, column=2)
        self.np_combo = ttk.Combobox(control, width=20, state="readonly")
        self.np_combo.grid(row=1, column=3)

        self.factors = ['Dose', 'Radiation', 'CellLine', 'NP']
        self.factor_vars = {}
        tk.Label(control, text="Factors:").grid(row=2, column=0)
        for i, f in enumerate(self.factors):
            var = tk.BooleanVar(value=(f == 'Dose'))
            cb = tk.Checkbutton(control, text=f, variable=var)
            cb.grid(row=2, column=1 + i, sticky="w")
            self.factor_vars[f] = var

        self.outlier_var = tk.BooleanVar()
        self.derived_var = tk.BooleanVar()
        tk.Checkbutton(control, text="Outlier Removal", variable=self.outlier_var).grid(row=3, column=0, sticky="w")
        tk.Checkbutton(control, text="Derived Vars", variable=self.derived_var).grid(row=3, column=1, sticky="w")

        tk.Label(control, text="Normalize:").grid(row=3, column=2)
        self.norm_combo = ttk.Combobox(control, width=12, state="readonly")
        self.norm_combo['values'] = ['None', 'log1p', 'zscore', 'minmax']
        self.norm_combo.set("None")
        self.norm_combo.grid(row=3, column=3)

        tk.Button(control, text="🚀 Analyze", command=self.run_analysis, bg="#4CAF50", fg="white").grid(row=4, column=0, columnspan=4, pady=5)

        # ==== Output Box ====
        out_frame = tk.LabelFrame(left, text="📄 Results")
        out_frame.pack(fill=tk.BOTH, expand=True, padx=8, pady=5)
        self.output_text = tk.Text(out_frame, wrap=tk.WORD, font=("Courier", 9))
        self.output_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar = tk.Scrollbar(out_frame, command=self.output_text.yview)
        self.output_text.config(yscrollcommand=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # ==== Graph Container ====
        self.graph_canvas_container = tk.Canvas(right)
        self.graph_canvas_container.pack(fill=tk.BOTH, expand=True)

    def log(self, text):
        self.output_text.insert(tk.END, text + "\n")
        self.output_text.see(tk.END)

    def update_np_options(self, event=None):
        val = self.cellline_combo.get()
        if val == "A549":
            self.np_combo['values'] = ['--', 'NDAuNP', 'SemNDAuNP']
        elif val == "MCF7":
            self.np_combo['values'] = ['--', 'AuNP', 'SemAuNP']
        else:
            self.np_combo['values'] = ['--']
        self.np_combo.set('--')

    def load_folder(self):
        folder = filedialog.askdirectory()
        if not folder: return
        self.df = load_all_aggregated_data(folder)
        if self.df.empty:
            messagebox.showerror("Error", "No data found.")
            return
        for col in ['CellLine', 'NP', 'Radiation', 'Dose']:
            self.df[col] = self.df[col].astype(str).str.strip()
        self.response_combo['values'] = list(self.df.select_dtypes(include=np.number).columns)
        self.response_combo.set("")
        self.cellline_combo['values'] = ['--'] + sorted(self.df['CellLine'].unique())
        self.cellline_combo.set('--')
        self.np_combo['values'] = ['--']
        self.np_combo.set('--')
        self.log("✔️ Data loaded.")

    def run_analysis(self):
        self.output_text.delete("1.0", tk.END)
        if self.df.empty:
            messagebox.showerror("Error", "Load data first.")
            return

        df = self.df.copy()
        y = self.response_combo.get()
        factors = [f for f, v in self.factor_vars.items() if v.get()]
        if not y or not factors:
            self.log("❗ Select a response variable and factors.")
            return

        # Filters
        if (cl := self.cellline_combo.get()) != '--':
            df = df[df['CellLine'] == cl]
        if (np_type := self.np_combo.get()) != '--':
            df = df[df['NP'] == np_type]
        df['Dose_numeric'] = pd.to_numeric(df['Dose'].str.replace("Gy", "").str.strip(), errors='coerce')
        df = df.dropna(subset=[y])

        if self.derived_var.get():
            df = create_derived_vars(df)
            self.log("📐 Derived variables added.")
        if self.outlier_var.get():
            df, out = remove_outliers(df, y)
            self.log(f"🧹 Removed outliers: {out}")
        if df.empty or len(df) < 5:
            self.log("⚠️ Too few data points.")
            return
        if (norm := self.norm_combo.get()) != "None":
            df = apply_normalization(df, y, norm)
            self.log(f"📊 Normalized using: {norm}")

        output_dir = make_output_dir(cl or "ALL", "ALL", np_type or "ALL")

        # === ANOVA
        try:
            model, anova = perform_anova(df, y, factors)
            anova.to_csv(os.path.join(output_dir, "anova.csv"))
            self.log("📈 ANOVA:\n" + anova.to_string())
        except Exception as e:
            self.log(f"❌ ANOVA failed: {e}")
            return

        # === Tukey
        for f in factors:
            try:
                result, data = run_tukey(df, y, f)
                pd.DataFrame(data[1:], columns=data[0]).to_csv(os.path.join(output_dir, f'tukey_{f}.csv'), index=False)
                self.log(f"📌 Tukey HSD ({f}):\n{result}")
            except Exception as e:
                self.log(f"❌ Tukey error ({f}): {e}")

        # === Main Plot Grid
        try:
            from matplotlib.figure import Figure
            import matplotlib.pyplot as plt
            fig, axs = plt.subplots(2, 2, figsize=(12, 8))
            fig.suptitle(f'{y} vs Factors', fontsize=16)

            try:
                order = sorted(df['Dose'].unique(), key=lambda d: float(str(d).replace("Gy", "")))
            except:
                order = None

            sns.violinplot(data=df, x='Dose', y=y, ax=axs[0, 0], inner='quartile', order=order)
            axs[0, 0].set_title("Violin Plot")

            sns.boxplot(data=df, x='Dose', y=y, ax=axs[0, 1], order=order)
            axs[0, 1].set_title("Boxplot")

            sns.histplot(data=df, x=y, kde=True, ax=axs[1, 0])
            axs[1, 0].set_title("Histogram")

            sns.regplot(data=df, x='Dose_numeric', y=y, ax=axs[1, 1], scatter=True)
            axs[1, 1].set_title("Linear Regression")

            fig.tight_layout()
            fig.savefig(os.path.join(output_dir, f"{y}_plot_grid.png"))

            for widget in self.graph_canvas_container.winfo_children():
                widget.destroy()
            canvas = FigureCanvasTkAgg(fig, master=self.graph_canvas_container)
            canvas.draw()
            canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        except Exception as e:
            self.log(f"❌ Grid plot error: {e}")

        # === Regression + Conclusion + Regressions plot
        try:
            if 'Dose_numeric' in df.columns:
                cat = factors[1] if len(factors) > 1 else factors[0]
                model, summary = run_regression(df, y, 'Dose_numeric', cat)
                with open(os.path.join(output_dir, "regression.txt"), "w") as f:
                    f.write(summary)
                self.log("\n📉 Regression summary:\n" + summary.splitlines()[0])

                conclusion = generate_conclusion(model, y, cat)
                with open(os.path.join(output_dir, "conclusion.txt"), "w") as f:
                    f.write(conclusion)
                self.log("\n🧠 Conclusion:\n" + conclusion)

                reg_fig = plot_regression_models(df, "Dose_numeric", y,
                            save_path=os.path.join(output_dir, f"{y}_regression_models.png"))
        except Exception as e:
            self.log(f"❌ Regression error: {e}")

        df.to_csv(os.path.join(output_dir, "filtered_data.csv"), index=False)
        self.log(f"\n✅ Saved in: {output_dir}")


# ====== RUN APP ======
if __name__ == "__main__":
    root = tk.Tk()
    app = AnalyzerApp(root)
    root.mainloop()
