import matplotlib.pyplot as plt
import sys
import pandas as pd

def plot_exam_marks(df, exam):
    # Filter out rows with 'a' marks in the specified exam
    df = df[df[exam] != 'a']

    # Convert the specified exam column to numeric using .loc
    df.loc[:, exam] = pd.to_numeric(df[exam])

    # Sorting DataFrame by Roll_Number
    df = df.sort_values(by='Roll_Number')

    # Plotting
    plt.figure(figsize=(10, 6))
    plt.plot(df['Roll_Number'], df[exam], marker='o', linestyle='-')
    plt.title(f'{exam} Marks vs Roll Number')
    plt.xlabel('Roll Number')
    plt.ylabel(f'{exam} Marks')
    plt.xticks(rotation=45)
    plt.grid(True)
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <exam>")
        sys.exit(1)
    
    # Read main.csv file into a pandas DataFrame
    df = pd.read_csv('main.csv')

    # Get the exam from the command-line argument
    exam = sys.argv[1]

    # Plot the specified exam marks
    plot_exam_marks(df, exam)
