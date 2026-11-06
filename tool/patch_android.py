"""Run after `flutter create` + `flutter pub get` (see .github/workflows/build.yml).

1. Signs release builds with android/keystore/release.jks, so every new
   version installs over the previous one and keeps your data.
"""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
android = root / "android"
props = {}
for line in (android / "keystore" / "key.properties").read_text().splitlines():
    if "=" in line:
        k, v = line.split("=", 1)
        props[k.strip()] = v.strip()

kts = android / "app" / "build.gradle.kts"
groovy = android / "app" / "build.gradle"

if kts.exists():
    text = kts.read_text()
    if 'create("release")' not in text:
        block = (
            "    signingConfigs {\n"
            '        create("release") {\n'
            f'            storeFile = file("{props["storeFile"]}")\n'
            f'            storePassword = "{props["storePassword"]}"\n'
            f'            keyAlias = "{props["keyAlias"]}"\n'
            f'            keyPassword = "{props["keyPassword"]}"\n'
            "        }\n"
            "    }\n\n"
        )
        text, n = re.subn(r"(\n\s*buildTypes\s*\{)", "\n" + block.rstrip("\n") + r"\1", text, count=1)
        if n != 1:
            sys.exit("Could not find buildTypes in build.gradle.kts")
        text = text.replace('signingConfigs.getByName("debug")', 'signingConfigs.getByName("release")')
        kts.write_text(text)
    print("Patched", kts)
elif groovy.exists():
    text = groovy.read_text()
    if "signingConfigs {" not in text:
        block = (
            "    signingConfigs {\n"
            "        release {\n"
            f"            storeFile file('{props['storeFile']}')\n"
            f"            storePassword '{props['storePassword']}'\n"
            f"            keyAlias '{props['keyAlias']}'\n"
            f"            keyPassword '{props['keyPassword']}'\n"
            "        }\n"
            "    }\n"
        )
        text, n = re.subn(r"(\n\s*buildTypes\s*\{)", "\n" + block.rstrip("\n") + r"\1", text, count=1)
        if n != 1:
            sys.exit("Could not find buildTypes in build.gradle")
        text = re.sub(r"signingConfig\s*=?\s*signingConfigs\.debug", "signingConfig = signingConfigs.release", text)
        groovy.write_text(text)
    print("Patched", groovy)
else:
    sys.exit("No android/app/build.gradle(.kts) found - did flutter create run?")

