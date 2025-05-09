#!/bin/bash

# اتأكدي إنك دخلتي اسم الـ log file
if [ $# -ne 1 ]; then
    echo "استخدمي: $0 <log_file>"
    exit 1
fi

LOG_FILE="$1"
OUTPUT_FILE="analysis_results.txt"

# اتأكدي إن الـ log file موجود
if [ ! -f "$LOG_FILE" ]; then
    echo "الـ log file '$LOG_FILE' مش موجود!"
    exit 1
fi

# ابدأي الملف بتاع النتايج من الصفر
> "$OUTPUT_FILE"

# 1. عدد الطلبات
echo "1. عدد الطلبات" >> "$OUTPUT_FILE"
TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")
GET_REQUESTS=$(grep -c '"GET' "$LOG_FILE")
POST_REQUESTS=$(grep -c '"POST' "$LOG_FILE")
echo "إجمالي الطلبات: $TOTAL_REQUESTS" >> "$OUTPUT_FILE"
echo "طلبات GET: $GET_REQUESTS" >> "$OUTPUT_FILE"
echo "طلبات POST: $POST_REQUESTS" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 2. الـ IP addresses الفريدة
echo "2. الـ IP addresses الفريدة" >> "$OUTPUT_FILE"
UNIQUE_IPS=$(awk '{print $1}' "$LOG_FILE" | sort -u | wc -l)
echo "عدد الـ IPs الفريدة: $UNIQUE_IPS" >> "$OUTPUT_FILE"
echo "عدد طلبات GET و POST لكل IP:" >> "$OUTPUT_FILE"
awk '{ip=$1; if ($6 ~ /GET/) get[ip]++; if ($6 ~ /POST/) post[ip]++} 
     END {for (ip in get) printf "%s: GET=%d, POST=%d\n", ip, get[ip], post[ip]}' "$LOG_FILE" | sort >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 3. الطلبات الفاشلة
echo "3. الطلبات الفاشلة" >> "$OUTPUT_FILE"
FAILED_REQUESTS=$(awk '$9 ~ /^[4|5][0-9][0-9]$/ {count++} END {print count+0}' "$LOG_FILE")
FAIL_PERCENT=$(echo "scale=2; ($FAILED_REQUESTS / $TOTAL_REQUESTS) * 100" | bc)
echo "عدد الطلبات الفاشلة: $FAILED_REQUESTS" >> "$OUTPUT_FILE"
echo "نسبة الفشل: $FAIL_PERCENT%" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 4. أكتر IP نشاط
echo "4. أكتر IP نشاط" >> "$OUTPUT_FILE"
TOP_IP=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print $2 " (" $1 " طلب)"}')
echo "أكتر IP نشاط: $TOP_IP" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 5. متوسط الطلبات في اليوم
echo "5. متوسط الطلبات في اليوم" >> "$OUTPUT_FILE"
DAYS=$(awk -F'[:[]' '{print $2}' "$LOG_FILE" | sort -u | wc -l)
AVG_REQUESTS=$(echo "scale=2; $TOTAL_REQUESTS / $DAYS" | bc)
echo "عدد الأيام: $DAYS" >> "$OUTPUT_FILE"
echo "متوسط الطلبات في اليوم: $AVG_REQUESTS" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 6. الأيام اللي فيها أكتر فشل
echo "6. الأيام اللي فيها أكتر فشل" >> "$OUTPUT_FILE"
awk '$9 ~ /^[4|5][0-9][0-9]$/ {split($4, date, ":"); print date[1]}' "$LOG_FILE" | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 7. الطلبات حسب الساعة
echo "7. الطلبات حسب الساعة" >> "$OUTPUT_FILE"
awk -F: '{print $2}' "$LOG_FILE" | sort | uniq -c | sort -n >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 8. تحليل أكواد الحالة
echo "8. تحليل أكواد الحالة" >> "$OUTPUT_FILE"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 9. أكتر IP بيستخدم GET و POST
echo "9. أكتر IP بيستخدم GET و POST" >> "$OUTPUT_FILE"
TOP_GET=$(awk '$6 ~ /GET/ {print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print $2 " (" $1 " طلب)"}')
TOP_POST=$(awk '$6 ~ /POST/ {print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print $2 " (" $1 " طلب)"}')
echo "أكتر IP بيستخدم GET: $TOP_GET" >> "$OUTPUT_FILE"
echo "أكتر IP بيستخدم POST: $TOP_POST" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 10. أنماط الفشل
echo "10. أنماط الفشل" >> "$OUTPUT_FILE"
awk '$9 ~ /^[4|5][0-9][0-9]$/ {print $4}' "$LOG_FILE" | sort | uniq -c | sort -nr >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "تم تحليل الـ log file! النتايج في $OUTPUT_FILE"
