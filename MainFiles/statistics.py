import pandas as pd
import numpy as np

# Read the main.csv file into a DataFrame
df = pd.read_csv('main.csv')

# Remove non-numeric values and convert to numeric
df.replace('a', np.nan, inplace=True)
df = df.apply(pd.to_numeric, errors='coerce')

# Calculate mean, median, and standard deviation for each column
statistics = {
    'Mean': df.mean(),
    'Median': df.median(),
    'Standard Deviation': df.std()
}

# Remove 'Name', 'Roll_Number', and 'dtype' rows from statistics
statistics = {key: stats.drop(['Name', 'Roll_Number']) for key, stats in statistics.items()}

# Print statistics for each exam and total
for column, stats in statistics.items():
    print(f"\n{column}:")
    print(stats)
