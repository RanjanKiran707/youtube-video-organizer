"""Records the YT Playlist demo flow, one take per step.

  python record_demo.py reset     reinstall the demo build (empty library) and open it
  python record_demo.py 1         record take 1 (can also be 2, 3, 4)
  python record_demo.py all       reset, then record every take in order
  python record_demo.py 2 norec   run take 2 without recording (to rehearse)

Takes are saved as out/take1.mkv ... Join them with make_video.py.
Needs the official YouTube app on the phone and an internet connection.
Take 2 shows Android's share sheet, which lists the phone owner's contacts, so
make_video.py blurs that band (BLUR in make_video.py).
"""
import sys
import time
import traceback

from adb_driver import *

dwell = time.sleep

YOUTUBE = "com.google.android.youtube"
VIDEO_URL = "https://youtube.com/watch?v=lHhRhPV--G0"   # "Flutter in 100 seconds" (Fireship)
APP_LABEL = "YT Playlist Demo"   # the demo build's name in the share sheet
FOLDER = "Talks"

# YouTube does not label its Share icon for uiautomator, so it is tapped by screen
# coordinates (1080x2412 phone). Re-measure it on a different phone.
SHARE_ICON = (774, 1007)


def take1():
    """Open a video in YouTube and press Share."""
    sh(f"am force-stop {YOUTUBE}")
    # Opens the video straight from its link. Searching would show the phone owner's
    # personal search suggestions in the recording.
    sh(f"am start -a android.intent.action.VIEW -d {VIDEO_URL} -p {YOUTUBE}"); dwell(9)
    tap_xy(*SHARE_ICON); dwell(3)


def take2():
    """YouTube's share row, then Android's share sheet: pick the app. (Contacts get blurred.)"""
    for _ in range(4):                       # the row of apps ends with "More"
        if find("More", exact=True):
            break
        swipe(900, 1550, 100, 1550, 400)
    tap("More", exact=True, pause=2.5)
    for _ in range(8):                       # the apps are a sideways-scrolling grid
        if find(APP_LABEL, exact=True):
            break
        swipe(950, 1800, 100, 1800, 400)
    tap(APP_LABEL, exact=True, pause=1)


def take3():
    """The app receives the link: make a folder and save the video."""
    sh(f"am force-stop {YOUTUBE}")           # no YouTube mini player floating over the app
    wait_for("New folder", 10)
    dwell(1)
    tap("New folder"); dwell(1)
    fill(0, FOLDER); hide_kb(); dwell(1)
    tap("Create", exact=True); dwell(2.5)
    if not wait_for(f"Save to {FOLDER}", 3):
        tap(FOLDER, pause=1.5)              # the new folder is listed but not opened yet
    wait_for(f"Save to {FOLDER}", 10)
    tap(f"Save to {FOLDER}", timeout=10); dwell(3)


def take4():
    """Open the folder and play the video."""
    tap(FOLDER); dwell(2)
    tap("Flutter in 100 seconds"); dwell(14)   # the saved video, played inside the app


TAKES = [take1, take2, take3, take4]


def run(i, record=True):
    rec = Rec(f"take{i}") if record else None
    try:
        TAKES[int(i) - 1]()
    except Exception:
        traceback.print_exc()
        shot(f"fail_take{i}")
        print("---- screen at failure ----")
        show()
        raise SystemExit(1)
    finally:
        if rec:
            rec.stop()


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    if cmd == "reset":
        fresh_install(); launch()
    elif cmd == "all":
        fresh_install()
        for n in range(1, len(TAKES) + 1):
            run(n)
    else:
        run(cmd, record=not (len(sys.argv) > 2 and sys.argv[2] == "norec"))
