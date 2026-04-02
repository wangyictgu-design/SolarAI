#!/bin/bash
# ============================================================
# Solar AI Inverter — Asset Copy Script
# Usage: cd /Users/lucky/Desktop/SolarAI && bash setup_assets.sh
# ============================================================
set -e

SRC="/Users/lucky/Desktop/Solar资料/图片"
DEST="/Users/lucky/Desktop/SolarAI/SolarAI/Resources/Assets.xcassets"

echo "Copying image assets..."

# App Icon
cp "$SRC/APP 图标.png" "$DEST/AppIcon.appiconset/icon.png"
echo "  [OK] App Icon"

# Login background
cp "$SRC/login_bg.png" "$DEST/login_bg.imageset/login_bg.png"
echo "  [OK] Login background"

# No connect diagram
cp "$SRC/流动图组/no_connect.png" "$DEST/no_connect.imageset/no_connect.png"
echo "  [OK] No connect diagram"

# PAYGO background
cp "$SRC/流动图组/input_code/input_code_bg2.png" "$DEST/input_code_bg2.imageset/input_code_bg2.png"
echo "  [OK] PAYGO background (input_code_bg2)"

# Flow animation frames
copy_flow() {
    local dir="$1"
    local prefix="$2"
    for i in 1 2 3 4 5 6; do
        cp "$SRC/流动图组/$dir/${prefix}${i}.png" "$DEST/${prefix}${i}.imageset/${prefix}${i}.png"
    done
    echo "  [OK] Flow: $dir"
}

copy_flow "b-Inver-l"         "b_inver_l"
copy_flow "gr-inver-b"        "gr_inver_b"
copy_flow "gr-inver-l"        "gr_inver_l"
copy_flow "gr-inver-l-b"      "gr_inver_l_b"
copy_flow "pv-inver-b"        "pv_inver_b"
copy_flow "pv-inver-l"        "pv_inver_l"
copy_flow "pv-inver-l-b"      "pv_inver_l_b"
copy_flow "pv-b-inver-l"      "pvb_inver_l"
copy_flow "pv-gr-inver-l-b"   "pvgrid_inver_l_b"

# Orange hardware icons (图标橙色/1.png-16.png → hw_orange_0-15)
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
    idx=$((i - 1))
    cp "$SRC/图标橙色/${i}.png" "$DEST/hw_orange_${idx}.imageset/hw_orange_${idx}.png"
done
echo "  [OK] 16 orange icons"

# Gray hardware icons (原图/)
cp "$SRC/原图/App 图标1.png"   "$DEST/hw_gray_0.imageset/hw_gray_0.png"
cp "$SRC/原图/App 图标2.png"   "$DEST/hw_gray_1.imageset/hw_gray_1.png"
cp "$SRC/原图/App 图标3.png"   "$DEST/hw_gray_2.imageset/hw_gray_2.png"
cp "$SRC/原图/App 图标6.png"   "$DEST/hw_gray_3.imageset/hw_gray_3.png"
cp "$SRC/原图/App 图标18.png"  "$DEST/hw_gray_4.imageset/hw_gray_4.png"
cp "$SRC/原图/App 图标7.png"   "$DEST/hw_gray_5.imageset/hw_gray_5.png"
cp "$SRC/原图/App 图标8.png"   "$DEST/hw_gray_6.imageset/hw_gray_6.png"
cp "$SRC/原图/App 图标9.png"   "$DEST/hw_gray_7.imageset/hw_gray_7.png"
cp "$SRC/原图/App 图标10.png"  "$DEST/hw_gray_8.imageset/hw_gray_8.png"
cp "$SRC/原图/App 图标11.png"  "$DEST/hw_gray_9.imageset/hw_gray_9.png"
cp "$SRC/原图/App 图标19.png"  "$DEST/hw_gray_10.imageset/hw_gray_10.png"
cp "$SRC/原图/App 图标12.png"  "$DEST/hw_gray_11.imageset/hw_gray_11.png"
cp "$SRC/原图/App 图标13.png"  "$DEST/hw_gray_12.imageset/hw_gray_12.png"
cp "$SRC/原图/App 图标14.png"  "$DEST/hw_gray_13.imageset/hw_gray_13.png"
cp "$SRC/原图/App 图标12.png"  "$DEST/hw_gray_14.imageset/hw_gray_14.png"
cp "$SRC/原图/App 图标12.png"  "$DEST/hw_gray_15.imageset/hw_gray_15.png"
echo "  [OK] 16 gray icons"

echo ""
echo "All assets copied successfully!"
