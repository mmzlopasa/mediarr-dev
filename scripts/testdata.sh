#!/bin/sh
# Builds the mixed test library. Runs in the dev image through `make testdata`.
# SCALE is a percentage of the full set of about 2,000 files.
set -eu

if [ "${1:-}" = "--one" ]; then
	ONE=1
else
	ONE=0
fi
OUT=${1:-}
SCALE=${2:-100}
JOBS=${JOBS:-2}
[ "$ONE" = 1 ] || mkdir -p "$OUT"/jpeg "$OUT"/png "$OUT"/webp "$OUT"/avif "$OUT"/heic "$OUT"/screenshots "$OUT"/panorama \
	"$OUT"/video "$OUT"/live "$OUT"/raw "$OUT"/broken

count() { echo $(($1 * SCALE / 100 + 1)); }

# Noise over a gradient: unique per file, and as hard to compress as real photos.
image() {
	w=$1 h=$2 out=$3
	# The seed matters: vips otherwise repeats the same noise, which would create duplicate files.
	vips gaussnoise "$out.v" "$w" "$h" --sigma 22 --mean 120 --seed "$(od -An -N3 -tu4 /dev/urandom | tr -d ' ')"
	# 8-bit, because noise around 120 in a 16-bit PNG would be almost black.
	vips cast "$out.v" "$out" uchar
	rm -f "$out.v"
}

gen_jpeg() {
	n=$1
	f=$OUT/jpeg/IMG_$n.jpg
	[ -e "$f" ] && return 0
	case $((n % 5)) in
	0) w=4032 h=3024 ;;
	1) w=3024 h=4032 ;;
	2) w=1920 h=1080 ;;
	3) w=1200 h=1600 ;;
	4) w=800 h=800 ;;
	esac
	image "$w" "$h" "$f"
	year=$((2015 + n % 11))
	month=$(printf '%02d' $((n % 12 + 1)))
	case $((n % 6)) in
	0) ;; # No EXIF at all.
	1) exiftool -q -overwrite_original "-DateTimeOriginal=$year:$month:15 12:00:00" "-OffsetTimeOriginal=+02:00" -Make=Apple "-Model=iPhone 15" "-GPSLatitude=45.81" -GPSLatitudeRef=N "-GPSLongitude=15.98" -GPSLongitudeRef=E "$f" ;;
	2) exiftool -q -overwrite_original "-DateTimeOriginal=$year:$month:20 23:59:30" -Make=Canon "-Model=EOS R6" -Orientation#=6 "$f" ;;
	3) exiftool -q -overwrite_original "-DateTimeOriginal=$year:$month:01 00:00:10" "-OffsetTimeOriginal=-07:00" -Make=Sony -Orientation#=3 "$f" ;;
	4) exiftool -q -q -m -overwrite_original "-DateTimeOriginal=0000:00:00 00:00:00" -Orientation#=8 "$f" ;;
	5) exiftool -q -overwrite_original "-Comment=Šišmiš na plaži" "-DateTimeOriginal=$year:$month:10 08:30:00" "$f" ;;
	esac
}

gen_simple() {
	dir=$1 ext=$2 n=$3
	f=$OUT/$dir/$dir-$n.$ext
	[ -e "$f" ] || image $((1000 + n % 7 * 400)) $((800 + n % 5 * 300)) "$f"
}

gen_heic() {
	n=$1
	f=$OUT/heic/IMG_$n.HEIC
	[ -e "$f" ] && return 0
	tmp=$(mktemp -u).jpg
	image 2016 1512 "$tmp"
	heif-enc -q 60 "$tmp" -o "$f" >/dev/null
	rm -f "$tmp"
}

gen_screenshot() {
	n=$1
	f=$OUT/screenshots/Screenshot_$n.png
	[ -e "$f" ] || image 1170 2532 "$f"
}

gen_panorama() {
	n=$1
	f=$OUT/panorama/PANO_$n.jpg
	[ -e "$f" ] || image 8000 1600 "$f"
}

gen_video() {
	n=$1
	case $((n % 4)) in
	0) f=$OUT/video/VID_$n.mp4 args="-c:v libx264 -pix_fmt yuv420p" ;;
	1) f=$OUT/video/VID_$n.mov args="-c:v libx264 -pix_fmt yuv420p" ;;
	2) f=$OUT/video/VID_$n.mp4 args="-c:v libx265 -pix_fmt yuv420p -tag:v hvc1" ;;
	3) f=$OUT/video/VID_$n.mkv args="-c:v libx264 -pix_fmt yuv420p" ;;
	esac
	[ -e "$f" ] && return 0
	# shellcheck disable=SC2086 # The arguments are meant to split.
	ffmpeg -nostdin -v error -f lavfi -i "testsrc2=duration=2:size=1280x720:rate=24,noise=alls=$((n % 40 + 5)):allf=t" $args -t 2 "$f"
}

# Synthetic: real iPhone pairs carry more metadata, so this does not replace testing with one.
gen_live() {
	n=$1
	photo=$OUT/live/LIVE_$n.HEIC
	movie=$OUT/live/LIVE_$n.MOV
	[ -e "$movie" ] && return 0
	id=$(printf '%08X-0000-4000-8000-%012X' "$n" "$n")
	tmp=$(mktemp -u).jpg
	image 1512 2016 "$tmp"
	heif-enc -q 60 "$tmp" -o "$photo" >/dev/null
	rm -f "$tmp"
	ffmpeg -nostdin -v error -f lavfi -i "testsrc2=duration=1:size=640x480:rate=24,noise=alls=$((n % 40 + 5)):allf=t" -c:v libx264 -pix_fmt yuv420p "$movie"
	exiftool -q -overwrite_original "-MakerNotes:ContentIdentifier=$id" "$photo" 2>/dev/null || true
	exiftool -q -overwrite_original "-QuickTime:ContentIdentifier=$id" "$movie" 2>/dev/null || true
}

gen_broken() {
	head -c 4096 /dev/urandom >"$OUT/broken/random.jpg"
	printf 'plain text' >"$OUT/broken/text.jpg"
	printf 'plain text' >"$OUT/broken/notes.txt"
	printf '\377\330\377\340' >"$OUT/broken/header-only.jpg"
	head -c 2048 /dev/urandom >"$OUT/broken/random.mp4"
	head -c 2048 /dev/urandom >"$OUT/broken/random.HEIC"
	first=$(find "$OUT/jpeg" -name '*.jpg' | head -1)
	if [ -n "$first" ]; then head -c 20000 "$first" >"$OUT/broken/truncated.jpg"; fi
}

run() {
	task=$1 total=$2
	echo "$task: $total"
	seq 1 "$total" | xargs -P "$JOBS" -I{} sh "$0" --one "$task" {} "$OUT" "$SCALE"
}

if [ "${1:-}" = "--one" ]; then
	OUT=$4
	case $2 in
	jpeg) gen_jpeg "$3" ;;
	png) gen_simple png png "$3" ;;
	webp) gen_simple webp webp "$3" ;;
	avif) gen_simple avif avif "$3" ;;
	heic) gen_heic "$3" ;;
	screenshot) gen_screenshot "$3" ;;
	panorama) gen_panorama "$3" ;;
	video) gen_video "$3" ;;
	live) gen_live "$3" ;;
	esac
	exit 0
fi

run jpeg "$(count 900)"
run png "$(count 120)"
run webp "$(count 100)"
run avif "$(count 60)"
run heic "$(count 250)"
run screenshot "$(count 100)"
run panorama "$(count 40)"
run video "$(count 120)"
run live "$(count 130)"

# Real cameras' RAW files, under free licences. See docs/testdata.md.
if [ -f "${RAW_LIST:-/dev/null}" ]; then
	while read -r sum url; do
		[ -n "$sum" ] || continue
		f=$OUT/raw/$(basename "$url" | sed "s/%20/ /g")
		[ -e "$f" ] || curl -fsSL --max-time 300 "$url" -o "$f"
		echo "$sum  $f" | sha256sum -c - >/dev/null
	done <"$RAW_LIST"
fi

gen_broken
echo "files: $(find "$OUT" -type f | wc -l), size: $(du -sh "$OUT" | cut -f1)"
