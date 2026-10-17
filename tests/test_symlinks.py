"""Exercise link cleanup in an isolated HOME, never the workstation's files."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class SymlinkTests(unittest.TestCase):
    def test_multiple_stale_links_spaces_and_regular_files(self):
        with tempfile.TemporaryDirectory(prefix='dot-links-') as directory:
            home = Path(directory)
            repo = home / '.dotfiles'
            (repo / '.funcs').mkdir(parents=True)
            (repo / '.zshrc').write_text('# test\n')
            (repo / '.funcs/kb.sh').write_text('alias s=kb\n')
            script = repo / 'symlinks.sh'
            shutil.copyfile(REPO / 'symlinks.sh', script)
            content = home / 'retained-content'
            content.write_text('keep me')
            stale = [home / 'old sheets.md', home / 'second-old-link']
            stale[0].symlink_to(content)
            stale[1].symlink_to(home / 'missing-target')
            regular = home / 'ordinary file'
            regular.write_text('never unlink this')
            old_directory = home / 'old directory'
            old_directory.mkdir()
            manifest = repo / '.symlinks'
            manifest.write_text(''.join(str(p) + '\n' for p in [*stale, regular, old_directory]))
            env = dict(os.environ, HOME=str(home))
            for _ in range(2):
                result = subprocess.run(['zsh', str(script)], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(all(not p.is_symlink() for p in stale))
            self.assertEqual(content.read_text(), 'keep me')
            self.assertEqual(regular.read_text(), 'never unlink this')
            self.assertTrue(old_directory.is_dir())
            self.assertEqual((home / '.funcs/kb.sh').resolve(), (repo / '.funcs/kb.sh').resolve())
            self.assertTrue(all(str(p) not in manifest.read_text() for p in stale))

    def test_kb_shortcut_in_fresh_shell(self):
        result = subprocess.run(['zsh', '-f', '-c', 'source "$1"; alias s; whence -w kb; whence -w sheets',
                                 'zsh', str(REPO / '.funcs/kb.sh')], capture_output=True, text=True)
        self.assertIn('s=kb', result.stdout)
        self.assertIn('kb: function', result.stdout)
        self.assertIn('sheets: none', result.stdout)
