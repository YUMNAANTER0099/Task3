#!/bin/bash

LOG_FILE="access.log"
OUTPUT_FILE="analysis_results.txt"

# Check if log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: $LOG_FILE not found!"
    exit 1
fi

# Initialize output file
> "$OUTPUT_FILE"

# 1. Request Statistics
total_requests=$(wc -l < "$LOG_FILE")
get_requests=$(grep -c 'GET' "$LOG_FILE")
post_requests=$(grep -c 'POST' "$LOG_FILE")
echo "1. إحصائيات الـ Requests" >> "$OUTPUT_FILE"
echo "إجمالي الـ Requests: $total_requests" >> "$OUTPUT_FILE"
echo "عدد الـ GET Requests: $get_requests" >> "$OUTPUT_FILE"
echo "عدد الـ POST Requests: $post_requests" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 2. Unique IP Addresses
unique_ips=$(awk '{print $1}' "$LOG_FILE" | sort | uniq | wc -l)
echo "2. الـ IP Addresses الفريدة" >> "$OUTPUT_FILE"
echo "عدد الـ IP Addresses الفريدة: $unique_ips" >> "$OUTPUT_FILE"
echo "تفاصيل الـ GET و POST لكل IP:" >> "$OUTPUT_FILE"
awk '{print $1, $6}' "$LOG_FILE" | sort | uniq -c | while read count ip method; do
    method=$(echo "$method" | tr -d '"')
    echo "IP: $ip, \"$method: $count" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# 3. Failed Requests
failed_requests=$(awk '$9 ~ /^[45]/ {count++} END {print count+0}' "$LOG_FILE")
failure_percentage=$(awk "BEGIN {printf \"%.2f\", ($failed_requests/$total_requests)*100}")
echo "3. الـ Requests الفاشلة" >> "$OUTPUT_FILE"
echo "عدد الـ Requests الفاشلة (4xx, 5xx): $failed_requests" >> "$OUTPUT_FILE"
echo "نسبة الفشل: $failure_percentage%" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 4. Most Active IP
most_active_ip=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
most_active_count=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print $1}')
echo "4. أكثر IP نشاطًا" >> "$OUTPUT_FILE"
echo "أكثر IP نشاطًا: $most_active_ip (عدد الـ Requests: $most_active_count)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 5. Daily Request Average
days=$(awk -F'[:[]' '{print $2}' "$LOG_FILE" | sort | uniq | wc -l)
daily_avg=$(awk "BEGIN {printf \"%.2f\", $total_requests/$days}")
echo "5. متوسط الـ Requests اليومي" >> "$OUTPUT_FILE"
echo "عدد الأيام: $days" >> "$OUTPUT_FILE"
echo "متوسط الـ Requests يوميًا: $daily_avg" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 6. Days with Highest Failures
echo "6. الأيام اللي فيها أعلى نسبة فشل" >> "$OUTPUT_FILE"
awk '$9 ~ /^[45]/ {print $4}' "$LOG_FILE" | cut -d: -f1 | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 7. Requests by Hour
echo "7. الـ Requests حسب الساعة" >> "$OUTPUT_FILE"
awk -F: '{print $2}' "$LOG_FILE" | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 8. Status Codes Distribution
echo "8. توزيع الـ Status Codes" >> "$OUTPUT_FILE"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 9. Most Active IPs by Method
echo "9. أكثر IP بيستخدم GET و POST" >> "$OUTPUT_FILE"
echo "أكثر IP بيستخدم GET:" >> "$OUTPUT_FILE"
awk '$6 ~ /GET/ {print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 >> "$OUTPUT_FILE"
echo "أكثر IP بيستخدم POST:" >> "$OUTPUT_FILE"
awk '$6 ~ /POST/ {print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 10. Patterns in Failed Requests
echo "10. أنماط في الـ Requests الفاشلة" >> "$OUTPUT_FILE"
awk '$9 ~ /^[45]/ {print $4}' "$LOG_FILE" | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"

echo "Analysis complete. Results saved to $OUTPUT_FILE"
