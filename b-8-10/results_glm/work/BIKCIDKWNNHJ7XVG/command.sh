import importlib

packages = ["sklearn", "cvxpy", "skglm", "statsmodels", "scipy", "skbio"]
versions = {}

for pkg in packages:
    try:
        mod = importlib.import_module(pkg)
        ver = getattr(mod, "__version__", "unknown")
        versions[pkg] = ver
        print(f"{pkg}: {ver}")
    except Exception:
        versions[pkg] = None
        print(f"{pkg}: NOT AVAILABLE")

# Check QuantileRegressor in sklearn
try:
    from sklearn.linear_model import QuantileRegressor
    print("sklearn.linear_model.QuantileRegressor: AVAILABLE")
except Exception:
    print("sklearn.linear_model.QuantileRegressor: NOT AVAILABLE")

# Check CLR in scikit-bio
try:
    from skbio.stats.composition import clr
    print("skbio.stats.composition.clr: AVAILABLE")
except Exception:
    print("skbio.stats.composition.clr: NOT AVAILABLE")

print("\nVersions summary:", versions)
