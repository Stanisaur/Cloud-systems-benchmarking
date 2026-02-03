#!/bin/bash
#
# ====================================================================
#              Reusable Function Library
# This file contains reusable bash functions.
# ====================================================================

# Picks a bucket with a normal-like distribution using pure Bash.
# This version allows for a configurable standard deviation and uses
# dithering to produce a statistically smooth distribution.
#
# Usage: pick_bucket_configurable <num_buckets> <std_dev_in_buckets>
#
# @param $1 num_buckets        Total number of buckets (e.g., 100)
# @param $2 std_dev_in_buckets The desired width of 1 standard deviation,
#                               measured in buckets. A smaller value creates a
#                               tighter, spikier distribution. A larger value
#                               creates a wider, flatter distribution.
#
pick_bucket_configurable() {
  local num_buckets=$1
  local std_dev_buckets=$2

  if [[ -z "$num_buckets" || "$num_buckets" -le 0 || -z "$std_dev_buckets" || "$std_dev_buckets" -le 0 ]]; then
    echo "Usage: pick_bucket_configurable <num_buckets> <std_dev_in_buckets>" >&2
    return 1
  fi

  # 1. Generate the base normal-like value via Central Limit Theorem
  local sum=0
  for ((i=0; i<12; i++)); do
    sum=$((sum + RANDOM))
  done

  # 2. Define the statistical properties of the sum
  # The mean of summing twelve $RANDOMs (0-32767) is ~196602.
  # We use a convenient nearby value.
  local mean=196608
  # The raw standard deviation of the sum is ~32768.
  local std_dev_raw=32768

  # Calculate the deviation from the mean
  local delta=$((sum - mean))

  # 3. Scale the deviation and apply dithering
  # The core idea is to map our raw z-score to a bucket offset.
  # z_raw = delta / std_dev_raw
  # offset = z_raw * std_dev_buckets
  # For integer math, we rearrange to: (delta * std_dev_buckets) / std_dev_raw

  # Add random noise (dithering) before division to smooth quantization error.
  # The dither value is between -std_dev_raw/2 and +std_dev_raw/2.
  local dither=$((RANDOM % std_dev_raw - (std_dev_raw / 2)))

  # The key calculation with the user-defined spread and dithering
  local offset=$(( (delta * std_dev_buckets + dither) / std_dev_raw ))

  # 4. Calculate final bucket and clamp to the valid range
  local mid=$(( (num_buckets + 1) / 2 ))
  local bucket=$(( mid + offset ))

  if (( bucket < 1 )); then
    bucket=1
  elif (( bucket > num_buckets )); then
    bucket=$num_buckets
  fi

  echo "$bucket"
}