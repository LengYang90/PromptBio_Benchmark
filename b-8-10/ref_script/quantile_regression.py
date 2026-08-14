## Description:
##      Model the conditional quantiles (τ = 0.1, 0.5, 0.9) of inflammatory 
##      marker IL-6 using relative abundances of 500 gut microbiome taxa. 
##      Apply centered log-ratio (clr) transformation to microbiome data and 
##      use elastic net penalized quantile regression. Report which microbial 
##      taxa are associated with extremely high IL-6 levels (τ = 0.9) but not 
##      with average levels.

import os
import numpy as np
import pandas as pd
from sklearn.linear_model import ElasticNet
from sklearn.base import BaseEstimator, RegressorMixin
import warnings
warnings.filterwarnings("ignore")

def ensure_dir_exists(directory):
    """Create directory if it doesn't exist."""
    if not os.path.exists(directory):
        os.makedirs(directory)

def load_data(data_file):
    """Load and prepare the microbiome IL-6 dataset."""
    print(f"Loading data from: {os.path.abspath(data_file)}")
    
    df = pd.read_csv(data_file)
    print(f"Dataset shape: {df.shape}")
    
    # Extract taxa columns
    taxa_cols = [col for col in df.columns if col.startswith('Taxon_')]
    
    print(f"\nData Overview:")
    print(f"  Samples: {len(df)}")
    print(f"  Taxa: {len(taxa_cols)}")
    print(f"  Target: IL6")
    
    # Display IL-6 statistics
    print(f"\nIL-6 statistics:")
    print(f"  Range: {df['IL6'].min():.3f} - {df['IL6'].max():.3f}")
    print(f"  Mean: {df['IL6'].mean():.3f}")
    print(f"  Median: {df['IL6'].median():.3f}")
    print(f"  Std: {df['IL6'].std():.3f}")
    
    print(f"\nIL-6 quantiles:")
    print(f"  tau=0.1 (10th percentile): {df['IL6'].quantile(0.1):.3f}")
    print(f"  tau=0.5 (median): {df['IL6'].quantile(0.5):.3f}")
    print(f"  tau=0.9 (90th percentile): {df['IL6'].quantile(0.9):.3f}")
    
    return df, taxa_cols

def clr_transformation(abundances):
    """
    Apply centered log-ratio (CLR) transformation to compositional data.
    CLR(x) = log(x / geometric_mean(x))
    """
    print(f"\nApplying CLR transformation...")
    
    # Add small pseudocount to avoid log(0)
    pseudocount = 1e-6
    abundances_shifted = abundances + pseudocount
    
    # Calculate geometric mean for each sample (row-wise)
    geo_mean = np.exp(np.log(abundances_shifted).mean(axis=1, keepdims=True))
    
    # Apply CLR transformation
    clr_data = np.log(abundances_shifted / geo_mean)
    
    print(f"  CLR transformed data shape: {clr_data.shape}")
    print(f"  CLR values range: {clr_data.min():.3f} to {clr_data.max():.3f}")
    
    return clr_data

class ElasticNetQuantileRegressor(BaseEstimator, RegressorMixin):
    """
    Elastic Net Penalized Quantile Regression using IRLS (Iteratively Reweighted Least Squares).
    
    This implements quantile regression with elastic net penalty by iteratively solving
    weighted least squares problems.
    """
    
    def __init__(self, quantile=0.5, alpha=0.1, l1_ratio=0.5, max_iter=100, tol=1e-4):
        self.quantile = quantile
        self.alpha = alpha
        self.l1_ratio = l1_ratio
        self.max_iter = max_iter
        self.tol = tol
        
    def fit(self, X, y):
        """Fit the model using IRLS for quantile regression with elastic net penalty."""
        n_samples, n_features = X.shape
        
        # Initialize with elastic net on original data
        init_model = ElasticNet(alpha=self.alpha, l1_ratio=self.l1_ratio, max_iter=1000, fit_intercept=False)
        init_model.fit(X, y)
        beta = init_model.coef_
        self.intercept_ = y.mean() - X.mean(axis=0) @ beta
        
        # IRLS for quantile regression
        tau = self.quantile
        
        for iteration in range(self.max_iter):
            # Compute residuals
            residuals = y - (self.intercept_ + X @ beta)
            
            # Compute weights for quantile loss
            # Weight = tau if residual > 0, else (tau - 1)
            # We use absolute residuals for stability
            abs_residuals = np.abs(residuals)
            weights = np.where(residuals >= 0, tau, tau - 1)
            weights = np.abs(weights)
            
            # Add small constant to avoid division by zero
            weights = weights / (abs_residuals + 0.01)
            weights = np.sqrt(weights)  # For weighted least squares
            
            # Weighted data
            X_weighted = X * weights[:, np.newaxis]
            y_weighted = y * weights
            
            # Fit elastic net on weighted data
            model = ElasticNet(alpha=self.alpha, l1_ratio=self.l1_ratio, max_iter=1000, fit_intercept=False)
            model.fit(X_weighted, y_weighted - self.intercept_ * weights)
            
            # Check convergence
            beta_new = model.coef_
            if np.max(np.abs(beta_new - beta)) < self.tol:
                beta = beta_new
                break
                
            beta = beta_new
        
        self.coef_ = beta
        return self
    
    def predict(self, X):
        """Predict using the fitted model."""
        return self.intercept_ + X @ self.coef_

def fit_quantile_regression(X, y, quantile, alpha=0.1, l1_ratio=0.5):
    """
    Fit elastic net penalized quantile regression.
    
    Parameters:
    - X: features (CLR-transformed microbiome data)
    - y: target (IL-6 levels)
    - quantile: tau value (0.1, 0.5, or 0.9)
    - alpha: regularization strength
    - l1_ratio: elastic net mixing parameter (0=L2, 1=L1)
    """
    print(f"\nFitting elastic net penalized quantile regression for tau = {quantile}...")
    print(f"  Alpha (regularization): {alpha}")
    print(f"  L1 ratio (elastic net): {l1_ratio}")
    
    # Fit elastic net quantile regression
    model = ElasticNetQuantileRegressor(
        quantile=quantile,
        alpha=alpha,
        l1_ratio=l1_ratio,
        max_iter=100,
        tol=1e-4
    )
    
    model.fit(X, y)
    
    # Get coefficients
    coef = model.coef_
    intercept = model.intercept_
    
    # Count non-zero coefficients
    non_zero = np.sum(np.abs(coef) > 1e-6)
    
    print(f"  Model fitted successfully")
    print(f"  Non-zero coefficients: {non_zero} / {len(coef)}")
    print(f"  Intercept: {intercept:.4f}")
    
    return model, coef, intercept

def identify_significant_taxa(coef_dict, taxa_cols, threshold=1e-6):
    """
    Identify taxa with non-zero coefficients for each quantile.
    """
    significant_taxa = {}
    
    for quantile, coef in coef_dict.items():
        # Find taxa with non-zero coefficients
        non_zero_mask = np.abs(coef) > threshold
        non_zero_indices = np.where(non_zero_mask)[0]
        
        taxa_info = []
        for idx in non_zero_indices:
            taxa_info.append({
                'Taxon': taxa_cols[idx],
                'Coefficient': coef[idx]
            })
        
        # Sort by absolute coefficient value
        taxa_info = sorted(taxa_info, key=lambda x: abs(x['Coefficient']), reverse=True)
        
        significant_taxa[quantile] = taxa_info
        
        print(f"\ntau = {quantile}: {len(taxa_info)} significant taxa")
        if len(taxa_info) > 0:
            print(f"  Top 5 by coefficient magnitude:")
            for i, info in enumerate(taxa_info[:5], 1):
                print(f"    {i}. {info['Taxon']}: {info['Coefficient']:.6f}")
    
    return significant_taxa

def find_high_but_not_average_taxa(significant_taxa):
    """
    Find taxa associated with extremely high IL-6 (tau=0.9) but not with average levels (tau=0.5).
    """
    print(f"\n" + "=" * 80)
    print("Finding taxa associated with high IL-6 (tau=0.9) but NOT with average IL-6 (tau=0.5)...")
    print("=" * 80)
    
    # Get taxon names for each quantile
    high_taxa = set([item['Taxon'] for item in significant_taxa[0.9]])
    median_taxa = set([item['Taxon'] for item in significant_taxa[0.5]])
    
    # Find taxa in high but not in median
    high_not_median = high_taxa - median_taxa
    
    print(f"\nTaxa associated with tau=0.9: {len(high_taxa)}")
    print(f"Taxa associated with tau=0.5: {len(median_taxa)}")
    print(f"Taxa in tau=0.9 but NOT in tau=0.5: {len(high_not_median)}")
    
    # Get coefficient information for these taxa
    high_specific_taxa = []
    for item in significant_taxa[0.9]:
        if item['Taxon'] in high_not_median:
            high_specific_taxa.append(item)
    
    # Sort by absolute coefficient
    high_specific_taxa = sorted(high_specific_taxa, key=lambda x: abs(x['Coefficient']), reverse=True)
    
    print(f"\nTop 10 taxa associated with high IL-6 but not average IL-6:")
    for i, info in enumerate(high_specific_taxa[:10], 1):
        print(f"  {i}. {info['Taxon']}: coefficient = {info['Coefficient']:.6f}")
    
    return high_specific_taxa

def save_results(significant_taxa, high_specific_taxa, output_dir):
    """Save results to CSV file (only high IL-6 specific taxa as requested)."""
    
    # Save high-specific taxa (the main result requested by the question)
    if len(high_specific_taxa) > 0:
        high_specific_df = pd.DataFrame(high_specific_taxa)
        high_specific_file = os.path.join(output_dir, 'high_il6_specific_taxa.csv')
        high_specific_df.to_csv(high_specific_file, index=False)
        print(f"\nHigh IL-6 specific taxa saved to: {os.path.abspath(high_specific_file)}")
        print(f"  Total taxa associated with high IL-6 but not average: {len(high_specific_taxa)}")
    else:
        print("\nNo taxa found that are specific to high IL-6 (not in average)")

def main():
    task_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(task_dir, "data")
    output_dir = os.path.join(task_dir, "ref_answer")
    
    # Ensure output directory exists
    ensure_dir_exists(output_dir)
    
    # File paths
    data_file = os.path.join(data_dir, "microbiome_il6_data.csv")
    
    # Load data
    df, taxa_cols = load_data(data_file)
    
    # Extract abundances and target
    X_abundances = df[taxa_cols].values
    y = df['IL6'].values
    
    # Apply CLR transformation
    X_clr = clr_transformation(X_abundances)
    
    # Fit quantile regression for τ = 0.1, 0.5, 0.9
    quantiles = [0.1, 0.5, 0.9]
    models = {}
    coef_dict = {}
    
    print(f"\n" + "=" * 80)
    print("Fitting Quantile Regression Models")
    print("=" * 80)
    
    for quantile in quantiles:
        model, coef, intercept = fit_quantile_regression(
            X_clr, y, 
            quantile=quantile, 
            alpha=0.1,  # Regularization strength for elastic net
            l1_ratio=0.5  # Elastic net mixing: 0.5 = equal L1 and L2 penalty
        )
        models[quantile] = model
        coef_dict[quantile] = coef
    
    # Identify significant taxa for each quantile
    print(f"\n" + "=" * 80)
    print("Identifying Significant Taxa")
    print("=" * 80)
    
    significant_taxa = identify_significant_taxa(coef_dict, taxa_cols)
    
    # Find taxa associated with high IL-6 but not average
    high_specific_taxa = find_high_but_not_average_taxa(significant_taxa)
    
    # Save results
    print(f"\n" + "=" * 80)
    print("Saving Results")
    print("=" * 80)
    
    save_results(significant_taxa, high_specific_taxa, output_dir)
    
    print(f"\n" + "=" * 80)
    print("Quantile Regression Analysis Complete!")
    print(f"  Total taxa analyzed: {len(taxa_cols)}")
    print(f"  Taxa specific to high IL-6: {len(high_specific_taxa)}")
    print(f"  Results saved to: {os.path.abspath(output_dir)}")
    print("=" * 80)

if __name__ == "__main__":
    main()

