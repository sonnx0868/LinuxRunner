#!/usr/bin/env python3
"""Generate the update document from the actual verified IPA, not CI defaults."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
from urllib.parse import quote
import zipfile


def generate(ipa, tag):
    with zipfile.ZipFile(ipa) as archive:
        info = plistlib.loads(archive.read('Payload/LinuxRunner.app/Info.plist'))
    channel = info.get('LinuxRunnerUpdateChannel')
    if channel not in ('m2-jit', 'm2-interpreter'):
        raise ValueError('Only a normal M2 release can become an app update')
    commit = info.get('LinuxRunnerSourceCommit', '')
    if not re.fullmatch('[0-9a-f]{40}', commit):
        raise ValueError('Missing source provenance')
    with ipa.open('rb') as handle:
        digest = hashlib.file_digest(handle, 'sha256').hexdigest()
    return dict(schema=1, channel=channel, bundleID=info['CFBundleIdentifier'],
                version=info['CFBundleShortVersionString'], build=int(info['CFBundleVersion']),
                sourceCommit=commit, size=ipa.stat().st_size, sha256=digest,
                ipaURL=f'https://github.com/sonnx0868/LinuxRunner/releases/download/{quote(tag, safe="")}/{quote(ipa.name, safe="")}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa', type=Path)
    parser.add_argument('--tag', required=True)
    args = parser.parse_args()
    document = generate(args.ipa, args.tag)
    output = args.ipa.parent / f'update-{document["channel"]}.json'
    output.write_text(json.dumps(document, indent=2) + '\n', encoding='utf-8')
    print(output)
