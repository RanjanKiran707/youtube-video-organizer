"""Joins out/take*.mkv into one captioned, compressed MP4 (default: ../../docs/demo.mp4).

  python make_video.py [output.mp4]

Env vars: FFMPEG (path to ffmpeg, default "ffmpeg"), DEMO_OUT (where the takes are),
CAPTION_FONT (a .ttf file, default C:/Windows/Fonts/arialbd.ttf).
"""
import os
import subprocess
import sys

from adb_driver import OUT, ROOT

FFMPEG = os.environ.get("FFMPEG", "ffmpeg")
FONT = os.environ.get("CAPTION_FONT", "C:/Windows/Fonts/arialbd.ttf").replace(":", "\\:")
TRIM_START = 3.0   # seconds of idle at the start of every take (scrcpy start-up)
SPEED = 1.25
W, H = 540, 1200

CAPTIONS = {
    1: "Open a video in YouTube and tap Share",
    2: "Pick YT Playlist in the share sheet",
    3: "Create a folder and save the video",
    4: "Play it from the folder",
}
# Takes whose share sheet lists the phone owner's contacts: {take: (y, height)} in phone pixels.
# That band is blurred after the clip is scaled.
BLUR = {2: (1260, 340)}


def clip(i):
    src = os.path.join(OUT, f"take{i}.mkv")
    dst = os.path.join(OUT, f"take{i}_cap.mp4")
    blur = ""
    if i in BLUR:
        k = H / 2412   # phone pixels -> output pixels (the phone is 1080x2412)
        y, h = int(BLUR[i][0] * k), int(BLUR[i][1] * k)
        blur = f"split[a][b];[b]crop=iw:{h}:0:{y},boxblur=12:3[bl];[a][bl]overlay=0:{y},"
    vf = (
        # scrcpy tags the stream with an odd colour matrix that breaks scaling, so reset it
        "setparams=colorspace=bt709:color_primaries=bt709:color_trc=bt709,"
        f"scale={W}:{H}:force_original_aspect_ratio=decrease,pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color=white,{blur}"
        f"setpts=PTS/{SPEED},fps=30,"
        f"drawtext=fontfile='{FONT}':text='{CAPTIONS[i]}':fontcolor=white:fontsize=26:"
        "box=1:boxcolor=0x1d4ed8@0.92:boxborderw=14:x=(w-text_w)/2:y=h-62"
    )
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-ss", str(TRIM_START), "-i", src, "-an",
                    "-vf", vf, "-c:v", "libx264", "-crf", "27", "-pix_fmt", "yuv420p", dst], check=True)
    return dst


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "demo.mp4")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    clips = [clip(i) for i in sorted(CAPTIONS) if os.path.exists(os.path.join(OUT, f"take{i}.mkv"))]
    lst = os.path.join(OUT, "clips.txt")
    with open(lst, "w") as f:
        f.writelines(f"file '{c.replace(os.sep, '/')}'\n" for c in clips)
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", lst,
                    "-c", "copy", "-movflags", "+faststart", out], check=True)
    print(f"{out}: {os.path.getsize(out) / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
