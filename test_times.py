import subprocess
import time
import statistics

executables = [
    "dywan_time",
    "omp_dywan_time",
    "cu_dywan_time"
]

runs = 10

def measure_time(exe):
    times = []
    for _ in range(runs):
        start = time.perf_counter()
        result = subprocess.run(f"./{exe}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        end = time.perf_counter()
        if result.returncode != 0:
            print(f"Error: {exe} exited with code {result.returncode}")
            print(result.stderr.decode())
            return None
        times.append(end - start)
    return times

def print_stats(name, times):
    if times is None:
        print(f"Skipping {name} due to errors.")
        return
    print(f"Results for {name}:")
    print(f"  Runs: {len(times)}")
    print(f"  Min time   : {min(times):.5f} s")
    print(f"  Max time   : {max(times):.5f} s")
    print(f"  Mean time  : {statistics.mean(times):.5f} s")
    print(f"  Median time: {statistics.median(times):.5f} s")
    print()

def main():
    for exe in executables:
        times = measure_time(exe)
        print_stats(exe, times)
