#!/usr/bin/env python3
"""A killed Plasma child must export its actual shell wait status."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

bundle = Path(__file__).resolve().parents[3] / 'app/LinuxRunner/GUISupport.bundle'
with tempfile.TemporaryDirectory(prefix='lr-plasma-exit-') as temporary:
    root = Path(temporary)
    session = root / 'session'
    session.mkdir()
    home = root / 'home'
    home.mkdir()
    for name in ('desktop-components.sh', 'plasma-env.sh'):
        shutil.copy(bundle / name, root / name)
    fixtures = {
        'startplasma-x11': '#!/bin/sh\necho "fixture: Plasma child killed" >&2\nkill -KILL $$\n',
        'desktop-probe': '#!/bin/sh\nprintf "wm=1\\npanel=1\\nsurface=1\\nready=1\\n"\n',
    }
    for name, content in fixtures.items():
        (root / name).write_text(content)
        (root / name).chmod(0o755)
    result = subprocess.run(['/bin/sh', str(root / 'desktop-components.sh'), str(session)],
        env=dict(os.environ, PATH=f'{root}:/usr/bin:/bin', HOME=str(home),
                 XDG_CONFIG_HOME=str(home / '.config'), LR_DESKTOP_ENVIRONMENT='plasma'),
        capture_output=True, text=True, timeout=15)
    assert result.returncode == 1, (result.returncode, result.stdout, result.stderr)
    assert 'component_exited name=Plasma session (plasma.log)' in result.stdout, result.stdout
    assert 'status=137' in result.stdout, result.stdout
    assert 'fixture: Plasma child killed' in (session / 'plasma.log').read_text()
    print('PLASMA_EXIT_PASS: SIGKILL child retained as status=137; component log preserved')
