#!/usr/bin/env python3
"""Disposable libc-free guest; inject real host mmap ENOMEM after one ELF LOAD."""
import argparse, io, os, pathlib, subprocess, tarfile, tempfile
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--runtime',required=True)
p.add_argument('--fakefsify',required=True)
a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2]
runtime=str(pathlib.Path(a.runtime).resolve())
importer=str(pathlib.Path(a.fakefsify).resolve())
with tempfile.TemporaryDirectory(prefix='lr-exec-rollback-') as temp:
    work=pathlib.Path(temp)
    def run(*args,**kw): return subprocess.run(args,check=True,timeout=60,**kw)
    # Two distinct LOAD mappings so the failure happens after partial loading.
    script=work/'elf.ld'
    # 16 KiB boundary matters: an Apple ARM64 host rounds file offsets down
    # to 16 KiB, even though the guest uses 4 KiB pages.
    script.write_text('ENTRY(_start)\nPHDRS { h PT_LOAD FILEHDR PHDRS FLAGS(4); t PT_LOAD FLAGS(7); }\nSECTIONS { . = 0x400000 + SIZEOF_HEADERS; .header : { BYTE(0); } :h . = 0x404000; .text : { *(.text*) } :t .data : { *(.data*) } :t }\n')
    for name,src in [('exec-rollback','exec_rollback.S'),('exec-ok','exec_rollback_ok.S')]:
        obj=work/(name+'.o')
        run('clang','--target=aarch64-linux-gnu','-c',str(root/'tests/linuxrunner'/src),'-o',str(obj))
        run('ld.lld','-m','aarch64elf','-static','-T',str(script),str(obj),'-o',str(work/name))
    denied=bytearray((work/'exec-ok').read_bytes());denied[8:16]=b'LRDENY!!'
    (work/'deny-image').write_bytes(denied)
    archive=work/'root.tar.gz'
    with tarfile.open(archive,'w:gz') as tar:
        for name in ['bin','dev','proc','sys','tmp','run','etc']:
            info=tarfile.TarInfo(name);info.type=tarfile.DIRTYPE;info.mode=0o755;tar.addfile(info)
        for name in ['exec-rollback','exec-ok','deny-image']:
            content=(work/name).read_bytes();info=tarfile.TarInfo('bin/'+name)
            info.size=len(content);info.mode=0o755;tar.addfile(info,io.BytesIO(content))
    run(importer,str(archive),str(work/'root'))
    injection=work/'deny.dylib'
    run('clang','-dynamiclib',str(root/'tests/linuxrunner/exec_rollback_inject.c'),'-o',str(injection))
    result=run(runtime,'-f',str(work/'root'),'/bin/exec-rollback',
        env=dict(os.environ,DYLD_INSERT_LIBRARIES=str(injection)),capture_output=True,text=True)
    assert 'EXEC_ROLLBACK_PASS' in result.stdout, (result.stdout,result.stderr)
    print('EXEC_ROLLBACK_PASS: 32 partial-load ENOMEM rollbacks, preserved robust list, successful subsequent exec')
