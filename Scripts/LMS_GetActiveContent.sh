#!/bin/bash
#
# LMS Active Content Checker
# Bu script LMS sunucusunda çalıştırılmalı
# Gerçek fiziksel olarak bulunan içerikleri listeler
#
# Kullanım:
#   ./LMS_GetActiveContent.sh > active_content.json
#   scp active_content.json admin@windowsserver:/path/to/import/
#

echo "{"
echo '  "server": "LMS",'
echo '  "scan_date": "'$(date -Iseconds)'",'
echo '  "content": ['

# LMS içerik dizinleri (genellikle bunlardan biri kullanılır)
CONTENT_DIRS=(
    "/opt/lms/content"
    "/var/lms/content" 
    "/mnt/content"
    "/storage/content"
    "/opt/doremi/content"
    "/opt/qube/content"
)

# Gerçek içerik dizinini bul
CONTENT_DIR=""
for dir in "${CONTENT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        CONTENT_DIR="$dir"
        echo '    {"info": "Content directory found: '$dir'"},' >&2
        break
    fi
done

if [ -z "$CONTENT_DIR" ]; then
    echo '    {"error": "Content directory not found"}' >&2
    echo "  ]"
    echo "}"
    exit 1
fi

# CPL XML dosyalarını bul ve parse et
FIRST=true
find "$CONTENT_DIR" -type f -name "CPL_*.xml" -o -name "*_CPL.xml" | while read cpl_file; do
    if [ "$FIRST" = false ]; then
        echo ","
    fi
    FIRST=false
    
    # Film adını CPL dosyasından çıkar
    CONTENT_TITLE=$(grep -m 1 "<ContentTitleText>" "$cpl_file" | sed 's/.*<ContentTitleText>\(.*\)<\/ContentTitleText>.*/\1/')
    
    # İçerik türünü al
    CONTENT_KIND=$(grep -m 1 "<ContentKind>" "$cpl_file" | sed 's/.*<ContentKind>\(.*\)<\/ContentKind>.*/\1/')
    
    # Süreyi al (EditRate ve Duration'dan hesapla)
    DURATION=$(grep -m 1 "<Duration>" "$cpl_file" | sed 's/.*<Duration>\(.*\)<\/Duration>.*/\1/')
    EDIT_RATE=$(grep -m 1 "<EditRate>" "$cpl_file" | sed 's/.*<EditRate>\([0-9]*\).*/\1/')
    
    if [ -n "$DURATION" ] && [ -n "$EDIT_RATE" ] && [ "$EDIT_RATE" != "0" ]; then
        DURATION_MINUTES=$(echo "scale=2; $DURATION / $EDIT_RATE / 60" | bc)
    else
        DURATION_MINUTES="0"
    fi
    
    # Dosya boyutunu al
    DIR_SIZE=$(du -sh "$(dirname "$cpl_file")" 2>/dev/null | cut -f1)
    
    # Son değiştirilme tarihi
    LAST_MODIFIED=$(stat -c %Y "$cpl_file" 2>/dev/null || stat -f %m "$cpl_file" 2>/dev/null)
    
    # JSON output
    echo -n '    {'
    echo -n '"content_title": "'"${CONTENT_TITLE//\"/\\\"}"'",'
    echo -n '"content_kind": "'"${CONTENT_KIND}"'",'
    echo -n '"duration_minutes": '${DURATION_MINUTES:-0}','
    echo -n '"size": "'"${DIR_SIZE}"'",'
    echo -n '"cpl_file": "'"${cpl_file}"'",'
    echo -n '"last_modified": '${LAST_MODIFIED:-0}
    echo -n '}'
done

echo ""
echo "  ]"
echo "}"

