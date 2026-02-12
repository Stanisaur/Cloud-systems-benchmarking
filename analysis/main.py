import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import io
import numpy as np

# ---------------------------------------------------------
# 1. LOAD DATA
# ---------------------------------------------------------
# Replacing this string with: df = pd.read_csv('your_log_file.txt', ...) for real files
raw_data = """7003f01400d7 10.10.10.3 459
3df942e333a8 10.10.26.3 325
f5be104cab34 10.10.10.3 403
d216fe367263 10.10.10.3 468
7003f01400d7 10.10.10.3 392
3df942e333a8 10.10.26.3 350
127da4fbb6a5 10.10.21.4 382
f5be104cab34 10.10.10.3 511
d216fe367263 10.10.10.3 332
7003f01400d7 10.10.10.3 345
127da4fbb6a5 10.10.21.4 372
f5be104cab34 10.10.10.3 329
d216fe367263 10.10.10.3 324
8e4e623a5aee 10.10.27.3 424
7003f01400d7 10.10.10.3 315
b7bc623bd792 10.10.34.3 432
b4fb80ef6a82 10.10.25.3 359
3df942e333a8 10.10.26.3 1725
127da4fbb6a5 10.10.21.4 368
f5be104cab34 10.10.10.3 434
d216fe367263 10.10.10.3 360
7003f01400d7 10.10.10.3 376
8e4e623a5aee 10.10.27.3 438
b7bc623bd792 10.10.34.3 349
127da4fbb6a5 10.10.21.4 393
3df942e333a8 10.10.26.3 425
b4fb80ef6a82 10.10.25.3 935
f5be104cab34 10.10.10.3 714
7003f01400d7 10.10.10.3 493"""

# Parse the data
df = pd.read_csv(io.StringIO(raw_data), sep=" ", header=None, names=["bus_id", "user_ip", "latency"])

# Global Plot Settings
plt.style.use('seaborn-v0_8-whitegrid')
plt.rcParams['figure.figsize'] = (10, 6)

# ---------------------------------------------------------
# SECTION 1: BASELINE
# ---------------------------------------------------------

# Graph 1: Sysbench CPU Calibration
# Note: Since sysbench data isn't in the logs, we use placeholder data.
def plot_sysbench():
    # REPLACE these values with your actual sysbench results
    sysbench_data = {
        'Bare Metal': 5000, 
        'VM Instance': 4500, 
        'Container': 4200
    }
    
    plt.figure()
    bars = plt.bar(sysbench_data.keys(), sysbench_data.values(), color=['#4c72b0', '#55a868', '#c44e52'])
    plt.title('Sysbench CPU Calibration (Raw Compute Performance)')
    plt.ylabel('Events Per Second (Higher is Better)')
    plt.xlabel('Environment')
    
    # Add labels
    for bar in bars:
        yval = bar.get_height()
        plt.text(bar.get_x() + bar.get_width()/2, yval + 50, round(yval, 1), ha='center', va='bottom')
    
    plt.tight_layout()
    plt.show()

# ---------------------------------------------------------
# SECTION 2: USER EXPERIENCE & LATENCY
# ---------------------------------------------------------

# Graph 2: Latency Percentile Comparison (P50, P55, P95, P99)
def plot_latency_percentiles(df):
    percentiles = [50, 55, 95, 99]
    values = np.percentile(df['latency'], percentiles)
    
    plt.figure()
    bars = plt.bar([f'P{p}' for p in percentiles], values, color='#8172b3')
    plt.title('Latency Percentile Comparison')
    plt.ylabel('Latency (ms)')
    plt.xlabel('Percentile Rank')
    
    # Add value labels
    for bar in bars:
        height = bar.get_height()
        plt.text(bar.get_x() + bar.get_width()/2., height,
                 f'{int(height)}ms', ha='center', va='bottom')
    
    plt.tight_layout()
    plt.show()

# Graph 3: Cumulative Latency Distribution (CDF)
def plot_cdf(df):
    sorted_latency = np.sort(df['latency'])
    p = 1. * np.arange(len(sorted_latency)) / (len(sorted_latency) - 1)
    
    plt.figure()
    plt.plot(sorted_latency, p, marker='.', linestyle='none', color='#c44e52')
    plt.plot(sorted_latency, p, color='#c44e52', alpha=0.3) # Line connecting dots
    plt.title('Cumulative Latency Distribution')
    plt.xlabel('Latency (ms)')
    plt.ylabel('Probability (CDF)')
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    plt.tight_layout()
    plt.show()

# Graph 4: Inter-arrival Jitter (Time Series for Single Bus)
# Note: Uses latency sequence as proxy for time, and latency variation as jitter
def plot_single_bus_jitter(df):
    # Select the bus with the most data points
    top_bus = df['bus_id'].value_counts().idxmax()
    bus_data = df[df['bus_id'] == top_bus].reset_index()
    
    # Calculate Latency Jitter (Diff between consecutive latencies)
    # Using latency sequence to visualize "stutter"
    
    plt.figure()
    plt.plot(bus_data.index, bus_data['latency'], marker='o', linestyle='-', color='#55a868', label='Latency')
    
    # Highlight high latency spikes
    threshold = bus_data['latency'].quantile(0.95)
    spikes = bus_data[bus_data['latency'] > threshold]
    plt.scatter(spikes.index, spikes['latency'], color='red', label='Stutter/Lag Spike', zorder=5)

    plt.title(f'Message Timing Consistency (Bus: {top_bus})')
    plt.ylabel('End-to-End Latency (ms)')
    plt.xlabel('Message Sequence Number')
    plt.legend()
    plt.tight_layout()
    plt.show()

# Graph 5: Jitter Variance (Boxplot)
# Shows the spread of "Jitter" (Latency variation) across the system
def plot_jitter_variance(df):
    # Calculate Jitter for every bus (abs diff of consecutive latencies)
    df['jitter'] = df.groupby('bus_id')['latency'].diff().abs()
    
    plt.figure()
    # Boxplot of Jitter values
    sns.boxplot(y=df['jitter'].dropna(), color='#ccb974')
    plt.title('Jitter Variance (Latency Instability Range)')
    plt.ylabel('Latency Variation / Jitter (ms)')
    
    # Annotate stats
    jitter_std = df['jitter'].std()
    plt.text(0.1, df['jitter'].max(), f'Std Dev: {jitter_std:.2f}ms', bbox=dict(facecolor='white', alpha=0.5))
    
    plt.tight_layout()
    plt.show()

# Graph 6: Age of Information (AoI)
# Tracking data freshness (Latency) over time
def plot_aoi(df):
    # Assuming the log is chronological, we plot latency over the global sequence
    plt.figure()
    plt.plot(df.index, df['latency'], color='#64b5cd', alpha=0.8, linewidth=1)
    
    # Add a moving average to show trend
    window = 5
    if len(df) > window:
        ma = df['latency'].rolling(window=window).mean()
        plt.plot(df.index, ma, color='#4c72b0', linewidth=2, label=f'{window}-Point Moving Avg')
    
    plt.title('Age of Information (Data Freshness Over Time)')
    plt.ylabel('Delay (ms)')
    plt.xlabel('Global Message Sequence')
    plt.legend()
    plt.tight_layout()
    plt.show()

# ---------------------------------------------------------
# EXECUTE PLOTS
# ---------------------------------------------------------
if __name__ == "__main__":
    print("Generating Section 1 Graphs...")
    plot_sysbench()
    
    print("Generating Section 2 Graphs...")
    plot_latency_percentiles(df)
    plot_cdf(df)
    plot_single_bus_jitter(df)
    plot_jitter_variance(df)
    plot_aoi(df)