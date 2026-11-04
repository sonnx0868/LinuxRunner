#!/usr/bin/env python3
"""Publish a verified M2 IPA and manifest to the optimized fork's Releases.

Use GITHUB_RELEASE_TOKEN in CI, or --git-credential for an existing local Git
login. No credentials are written to files or printed. A draft is made public
only after both assets and their checksum have finished uploading.
"""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request

REPO = 'sonnx0868/LinuxRunner'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa', type=Path)
    parser.add_argument('--git-credential', action='store_true')
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location('update_manifest', Path(__file__).with_name('make-update-manifest.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    document = module.generate(args.ipa, 'pending')
    tag = f'm2-build-{document["build"]}'
    document = module.generate(args.ipa, tag)
    token = os.environ.get('GITHUB_RELEASE_TOKEN')
    if args.git_credential:
        process = subprocess.run(['git', '-c', 'credential.interactive=never', 'credential', 'fill'],
                                 input='protocol=https\nhost=github.com\nusername=sonnx0868\n\n',
                                 text=True, capture_output=True, check=True)
        fields = dict(line.split('=', 1) for line in process.stdout.splitlines() if '=' in line)
        token = fields.get('password')
    if not token:
        raise SystemExit('Provide GITHUB_RELEASE_TOKEN or use --git-credential with an existing login.')

    def request(url, method='GET', body=None, content_type='application/json'):
        req = urllib.request.Request(url, data=body, method=method, headers={
            'Authorization': f'Bearer {token}', 'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': content_type,
            'User-Agent': 'LinuxRunner-Release'})
        with urllib.request.urlopen(req, timeout=180) as response:
            return json.load(response)

    api = f'https://api.github.com/repos/{REPO}'
    # Refuse to overwrite an existing release or use a different account.
    user = request('https://api.github.com/user')
    if user['login'].lower() != 'sonnx0868':
        raise SystemExit('The existing credential is not for sonnx0868.')
    try:
        existing = request(f'{api}/releases/tags/{tag}')
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        existing = None
    if existing:
        raise SystemExit(f'Release {tag} already exists; refusing to replace it.')
    notes = (f'iPad M2 performance build {document["build"]}.\n\n'
             'Download the IPA, open it in LCSign, then sign and install with your existing app identity. '
             'This IPA has an ad-hoc signature and requires your own signing/provisioning.\n\n'
             f'Source: {document["sourceCommit"]}\n'
             'Includes Debian Chromium launcher compatibility for the zygote exit-127 crash, '
             'Chromium exec rollback repair, M2 profile, raw keyboard input, '
             'StikDebug authorization request and in-app update downloads. '
             'The Chromium compatibility flags reduce browser isolation inside the Linux guest. '
             'Chromium startup, performance and LCSign import still require testing on the iPad.')
    release = request(f'{api}/releases', 'POST', json.dumps(dict(
        tag_name=tag, target_commitish=document['sourceCommit'],
        name=f'LinuxRunner M2 · build {document["build"]}', body=notes, draft=True, prerelease=False)).encode())
    upload = release['upload_url'].split('{')[0]
    assets = [(args.ipa.name, args.ipa.read_bytes(), 'application/octet-stream'),
              (f'update-{document["channel"]}.json', (json.dumps(document, indent=2) + '\n').encode(), 'application/json'),
              (args.ipa.name + '.sha256', f'{document["sha256"]}  {args.ipa.name}\n'.encode(), 'text/plain')]
    for name, data, mime in assets:
        result = request(upload + '?name=' + urllib.parse.quote(name), 'POST', data, mime)
        if result.get('size') != len(data) or result.get('state') != 'uploaded':
            raise RuntimeError('Release asset upload incomplete; the release remains a draft.')
        digest = result.get('digest')
        if digest and digest != 'sha256:' + hashlib.sha256(data).hexdigest():
            raise RuntimeError('Release asset digest mismatch; the release remains a draft.')
    result = request(release['url'], 'PATCH', json.dumps({'draft': False, 'make_latest': 'true'}).encode())
    print(result['html_url'])


if __name__ == '__main__':
    main()
