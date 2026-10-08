"""Small adb helper for driving the YT Playlist demo build on a real phone.

Finds buttons by their visible text (Flutter exposes labels to uiautomator),
so scripts do not depend on screen coordinates. Configure with env vars:

  ADB      path to adb               (default: "adb", must be on PATH)
  SCRCPY   path to scrcpy            (default: "scrcpy", must be on PATH)
  DEMO_PKG package id of demo build  (default: com.example.youtube_saver.demo)
  DEMO_APK debug APK to (re)install  (default: build/app/outputs/flutter-apk/app-debug.apk)
  DEMO_OUT folder for recordings     (default: scripts/demo/out)
"""
import os
import re
import subprocess
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ADB = os.environ.get("ADB", "adb")
SCRCPY = os.environ.get("SCRCPY", "scrcpy")
PKG = os.environ.get("DEMO_PKG", "com.example.youtube_saver.demo")
APK = os.environ.get("DEMO_APK", os.path.join(ROOT, "build", "app", "outputs", "flutter-apk", "app-debug.apk"))
OUT = os.environ.get("DEMO_OUT", os.path.join(HERE, "out"))
os.makedirs(OUT, exist_ok=True)

# Stops Git Bash on Windows from rewriting /sdcard/... paths.
_env = dict(os.environ, MSYS_NO_PATHCONV="1")


def adb(*args):
    return subprocess.run([ADB, *args], capture_output=True, env=_env).stdout


def sh(cmd):
    return adb("shell", cmd).decode("utf-8", "replace")


def dump():
    """Return every labelled node on screen as dicts (t=text, cx/cy=centre, b=bounds)."""
    x = ""
    for _ in range(3):
        sh("uiautomator dump /sdcard/ui.xml")
        x = adb("exec-out", "cat", "/sdcard/ui.xml").decode("utf-8", "replace")
        if "<node" in x:
            break
        time.sleep(0.5)
    nodes = []
    for m in re.finditer(r"<node([^>]*)>", x):
        a = m.group(1)
        g = lambda k: (re.search(k + r'="([^"]*)"', a) or [None, ""])[1]
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', a)
        if not b:
            continue
        x1, y1, x2, y2 = map(int, b.groups())
        nodes.append(dict(t=g("text") or g("content-desc"), cx=(x1 + x2) // 2,
                          cy=(y1 + y2) // 2, b=(x1, y1, x2, y2), cls=g("class")))
    return nodes


def show():
    """Print what is on screen (handy when a step fails)."""
    for n in dump():
        if n["t"]:
            print(repr(n["t"]), n["b"])


def find(text, exact=False):
    low = text.lower()
    return [n for n in dump() if n["t"] and (n["t"].lower() == low if exact else low in n["t"].lower())]


def wait_for(text, timeout=8, exact=False):
    end = time.time() + timeout
    while time.time() < end:
        r = find(text, exact)
        if r:
            return r
        time.sleep(0.4)
    return []


def tap_xy(x, y):
    sh(f"input tap {x} {y}")


def tap(text, exact=False, index=0, pause=0.9, timeout=8):
    r = wait_for(text, timeout, exact)
    if not r:
        raise RuntimeError(f"not found on screen: {text}")
    tap_xy(r[index]["cx"], r[index]["cy"])
    time.sleep(pause)


def swipe(x1, y1, x2, y2, ms=400, pause=0.8):
    sh(f"input swipe {x1} {y1} {x2} {y2} {ms}")
    time.sleep(pause)


def scroll_down(pause=0.8):
    swipe(540, 1700, 540, 700, 500, pause)


def back(pause=0.8):
    sh("input keyevent KEYCODE_BACK")
    time.sleep(pause)


def typ(text, pause=0.5):
    sh("input text " + text.replace(" ", "%s"))
    time.sleep(pause)


def edits():
    return [n for n in dump() if n["cls"].endswith("EditText")]


def fill(index, text, pause=0.6):
    """Tap the index-th text box on screen and type into it."""
    e = edits()[index]
    tap_xy(e["cx"], e["cy"])
    time.sleep(0.7)
    typ(text, pause)


def hide_kb():
    back(0.7)


def shot(name):
    p = os.path.join(OUT, name + ".png")
    with open(p, "wb") as f:
        f.write(adb("exec-out", "screencap", "-p"))
    return p


def launch():
    sh(f"monkey -p {PKG} -c android.intent.category.LAUNCHER 1")
    time.sleep(3)


def fresh_install():
    """Wipe the demo app's data. `pm clear` is blocked on some phones, so reinstall."""
    adb("uninstall", PKG)
    out = adb("install", "-r", APK).decode("utf-8", "replace")
    if "Success" not in out:
        raise RuntimeError(f"install failed: {out}")
    sh("input keyevent KEYCODE_WAKEUP")


class Rec:
    """Records the screen with scrcpy to OUT/<name>.mkv.

    `adb shell screenrecord` crashes on some phones, so scrcpy is used instead. MKV is used
    because it survives scrcpy being stopped abruptly; make_video.py converts it to MP4.
    Runs alongside an already open scrcpy mirror window.
    """

    def __init__(self, name):
        self.path = os.path.join(OUT, name + ".mkv")
        if os.path.exists(self.path):
            os.remove(self.path)
        self.p = subprocess.Popen(
            [SCRCPY, "--no-display", "--no-audio", "--no-control", "--max-fps", "30",
             "--record", self.path],
            env=dict(_env, ADB=ADB), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(4)  # let the stream start before the first tap

    def stop(self):
        time.sleep(1.5)
        self.p.kill()
        self.p.wait(timeout=20)
        time.sleep(1)
