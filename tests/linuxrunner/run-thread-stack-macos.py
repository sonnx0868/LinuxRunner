#!/usr/bin/env python3
"""Reproduce Chromium's 8 MiB stack mmap refusal against the actual runtime."""
import argparse
import io
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--runtime', required=True)
parser.add_argument('--fakefsify', required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
runtime = str(Path(args.runtime).resolve())
importer = str(Path(args.fakefsify).resolve())

def run(*command, **options):
    return subprocess.run(command, check=True, timeout=60, **options)

with tempfile.TemporaryDirectory(prefix='lr-thread-stack-') as temporary:
    work = Path(temporary)
    run('clang', '--target=aarch64-linux-gnu', '-c', str(repo / 'tests/linuxrunner/thread_stack.S'), '-o', str(work / 'stack.o'))
    run('ld.lld', '-m', 'aarch64elf', '-static', '-e', '_start', str(work / 'stack.o'), '-o', str(work / 'stack'))
    root_archive = work / 'root.tar.gz'
    with tarfile.open(root_archive, 'w:gz') as archive:
        for name in ['bin', 'dev', 'proc', 'sys', 'tmp', 'run', 'etc']:
            entry = tarfile.TarInfo(name)
            entry.type = tarfile.DIRTYPE
            entry.mode = 0o755
            archive.addfile(entry)
        data = (work / 'stack').read_bytes()
        entry = tarfile.TarInfo('bin/stack')
        entry.size = len(data)
        entry.mode = 0o755
        archive.addfile(entry, io.BytesIO(data))
    run(importer, str(root_archive), str(work / 'root'))
    injection = work / 'deny-stack.dylib'
    run('clang', '-dynamiclib', '-Wall', '-Wextra', '-Werror', str(repo / 'tests/linuxrunner/thread_stack_inject.c'), '-o', str(injection))
    result = run(runtime, '-f', str(work / 'root'), '/bin/stack', env=dict(os.environ, DYLD_INSERT_LIBRARIES=str(injection)), capture_output=True, text=True)
    assert 'THREAD_STACK_PASS' in result.stdout, (result.stdout, result.stderr)
    assert result.stderr.count('STACK_INJECTION: denied') == 1, result.stderr
    print('THREAD_STACK_PASS: 48 live 0x810000 reservations, host ENOMEM injection, sparse zero pages, guard EFAULT, reprotection, data retention and unmap')
