"""Integration tests: every note and remote lives in a disposable directory."""
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / '.python/kb.py'
SPEC = importlib.util.spec_from_file_location('kb', SCRIPT)
KB = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(KB)
REAL_GIT = shutil.which('git')


class WikiTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kb-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / 'home'
        self.home.mkdir()
        self.remote = self.base / 'remote.git'
        self.seed = self.base / 'seed'
        self.wiki = self.base / 'wiki'
        self.env = os.environ.copy()
        for key in list(self.env):
            if key.startswith(('GIT_', 'FZF_')) or key in ('KB_DIR', 'EDITOR'):
                self.env.pop(key)
        self.env.update(HOME=str(self.home), KB_DIR=str(self.wiki),
                        GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull,
                        GIT_AUTHOR_NAME='kb test', GIT_AUTHOR_EMAIL='kb-test@example.invalid',
                        GIT_COMMITTER_NAME='kb test', GIT_COMMITTER_EMAIL='kb-test@example.invalid')
        self.git(None, 'init', '--bare', '--initial-branch=main', self.remote)
        self.git(None, 'init', '--initial-branch=main', self.seed)
        (self.seed / 'Home.md').write_text('Welcome\n', encoding='utf-8')
        self.git(self.seed, 'add', 'Home.md')
        self.git(self.seed, 'commit', '-m', 'Seed')
        self.git(self.seed, 'remote', 'add', 'origin', self.remote)
        self.git(self.seed, 'push', '-u', 'origin', 'main')
        self.kb('init', '--remote', self.remote)

    def git(self, directory, *args, ok=True):
        command = [REAL_GIT]
        if directory:
            command += ['-C', str(directory)]
        result = subprocess.run(command + [str(a) for a in args], env=self.env,
                                capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        return result

    def kb(self, *args, ok=True):
        result = subprocess.run([sys.executable, str(SCRIPT), *map(str, args)],
                                env=self.env, capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def editor(self, text):
        editor = self.base / 'editor with spaces.py'
        editor.write_text('import pathlib, sys\npathlib.Path(sys.argv[-1]).write_text(' +
                          repr(text) + ', encoding="utf-8")\n')
        self.env['EDITOR'] = shlex.join([sys.executable, str(editor)])

    def picker(self, responses):
        """Drive interactive choices while the fuzzy matching tests use real fzf."""
        binary = self.base / 'picker-bin'
        binary.mkdir(exist_ok=True)
        log = self.base / 'picker-log.jsonl'
        log.unlink(missing_ok=True)
        program = binary / 'fzf'
        program.write_text('#!' + sys.executable + '\n' +
                           'import json, pathlib, sys\n' +
                           'log = pathlib.Path(' + repr(str(log)) + ')\n' +
                           'index = len(log.read_text().splitlines()) if log.exists() else 0\n' +
                           'data = {"args": sys.argv[1:], "input": sys.stdin.read()}\n' +
                           'with log.open("a") as stream: stream.write(json.dumps(data) + "\\n")\n' +
                           'response = ' + repr(responses) + '[index]\n' +
                           'if isinstance(response, int): sys.exit(response)\n' +
                           'query, key, name = response\n' +
                           'selected = next(row for row in data["input"].splitlines() '
                           'if row.split("\\t", 1)[0] == name)\n' +
                           'response = (query, key, selected)\n' +
                           'print("\\n".join(response))\n')
        program.chmod(0o755)
        self.env['PATH'] = str(binary) + os.pathsep + self.env['PATH']
        return log

    def network(self, mode):
        binary = self.base / 'bin'
        binary.mkdir(exist_ok=True)
        wrapper = binary / 'git'
        wrapper.write_text('#!' + sys.executable + '\n' +
                           'import os, subprocess, sys\n' +
                           'args = sys.argv[1:]\n' +
                           'mode = ' + repr(mode) + '\n' +
                           'network = any(a in args for a in ("fetch", "push", "ls-remote"))\n' +
                           'if mode == "offline" and network:\n'
                           '    sys.stderr.write("network unavailable\\n"); sys.exit(128)\n'
                           'if mode == "auth" and "fetch" in args:\n'
                           '    sys.stderr.write("Permission denied (publickey)\\n"); sys.exit(128)\n'
                           'if mode == "reject" and "push" in args:\n'
                           '    sys.stderr.write("rejected: fetch first\\n"); sys.exit(1)\n'
                           'if mode == "race" and "push" in args:\n'
                           '    import pathlib\n'
                           '    seed = ' + repr(str(self.seed)) + '\n'
                           '    pathlib.Path(seed, "Concurrent.md").write_text("Concurrent edit")\n'
                           '    for cmd in (["add", "Concurrent.md"], ["commit", "-m", "Concurrent"], ["push"]):\n'
                           '        subprocess.run([' + repr(REAL_GIT) + ', "-C", seed] + cmd, check=True)\n'
                           'if mode == "unknown" and "ls-remote" in args:\n'
                           '    sys.stderr.write("connection lost\\n"); sys.exit(128)\n'
                           'result = subprocess.run([' + repr(REAL_GIT) + '] + args)\n'
                           'if mode in ("lost-ack", "unknown") and "push" in args:\n'
                           '    sys.stderr.write("connection lost after push\\n"); sys.exit(128)\n'
                           'sys.exit(result.returncode)\n')
        wrapper.chmod(0o755)
        self.env['PATH'] = str(binary) + os.pathsep + os.environ['PATH']

    def remote_change(self, name='Home.md', data=b'Remote change\n'):
        path = self.seed / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if data is None:
            path.unlink()
        else:
            path.write_bytes(data)
        self.git(self.seed, 'add', '--all')
        self.git(self.seed, 'commit', '-m', 'Remote edit')
        self.git(self.seed, 'push')

    def head(self, directory=None):
        return self.git(directory or self.wiki, 'rev-parse', 'HEAD').stdout.strip()

    def test_init_full_clone_and_local_excludes(self):
        self.assertEqual(self.git(self.wiki, 'rev-parse', '--is-shallow-repository').stdout.strip(), 'false')
        self.assertFalse((self.wiki / '.gitignore').exists())
        self.assertIn('# kb:', (self.wiki / '.git/info/exclude').read_text())
        self.kb('init', '--remote', self.remote, ok=False)
        self.assertEqual(self.kb('read', 'Home').stdout, 'Welcome\n')

    def test_init_uses_origin_with_custom_default_remote(self):
        config = self.home / '.gitconfig'
        contents = '[clone]\n    defaultRemoteName = upstream\n'
        config.write_text(contents)
        self.env['GIT_CONFIG_GLOBAL'] = str(config)
        self.wiki = self.base / 'custom remote wiki'
        self.env['KB_DIR'] = str(self.wiki)
        self.kb('init', '--remote', self.remote)
        self.assertEqual(self.git(self.wiki, 'remote').stdout.strip(), 'origin')
        (self.wiki / 'Local.md').write_text('Local edit\n')
        self.kb('sync')
        self.assertEqual(self.head(), self.git(self.remote, 'rev-parse', 'main').stdout.strip())
        self.assertEqual(config.read_text(), contents)

    def test_sync_respects_global_excludes_but_search_includes_ignored_notes(self):
        excludes = self.base / 'global-ignore'
        excludes.write_text('*.zip\nPrivate.md\n*.txt\nHome.md\n')
        config = self.home / '.gitconfig'
        self.env['GIT_CONFIG_GLOBAL'] = str(config)
        self.git(None, 'config', '--file', config, 'core.excludesFile', excludes)
        source = self.base / 'archive.zip'
        source.write_bytes(b'attachment')
        self.kb('attach', source)
        (self.wiki / 'Private.md').write_text('Ignored searchable note\n')
        (self.wiki / 'scratch.txt').write_text('Ignored non-content file\n')
        (self.wiki / 'Home.md').write_text('Tracked modification\n')
        (self.wiki / 'Public.md').write_text('Public note\n')
        self.assertIn('Private.md', self.kb('search', '--filter', 'searchable').stdout)
        self.kb('sync')
        self.assertEqual(set(self.git(self.wiki, 'ls-files').stdout.splitlines()), {'Home.md', 'Public.md'})
        self.assertEqual((self.wiki / 'uploads/archive.zip').read_bytes(), b'attachment')
        self.assertTrue((self.wiki / 'Private.md').exists())
        self.assertTrue((self.wiki / 'scratch.txt').exists())
        self.assertEqual(self.git(self.wiki, 'show', 'HEAD:Home.md').stdout, 'Tracked modification\n')

    def test_sync_respects_local_excludes_before_validation(self):
        with (self.wiki / '.git/info/exclude').open('a') as stream:
            stream.write('\nPrivate.md\n')
        (self.wiki / 'Private.md').write_bytes(b'\xff')
        (self.wiki / 'Public.md').write_text('Publish this\n')
        self.kb('sync')
        self.assertNotIn('Private.md', self.git(self.wiki, 'ls-files').stdout)
        self.assertEqual((self.wiki / 'Private.md').read_bytes(), b'\xff')
        self.assertIn('Public.md', self.git(self.wiki, 'ls-files').stdout)

    def test_offline_unicode_editor_search_and_status(self):
        self.network('offline')
        self.editor('Un été à Paris\n')
        self.kb('new', 'Réseau privé/Été à Paris')
        self.assertEqual(self.kb('read', 'Réseau privé/Été à Paris.md').stdout, 'Un été à Paris\n')
        self.assertIn('Réseau privé/Été à Paris.md:1:', self.kb('search', '--filter', 'été').stdout)
        self.editor('Modification locale\n')
        self.kb('edit', 'Home')
        self.assertIn('Home.md', self.kb('search', '--filter', 'locale').stdout)
        self.assertIn('unknown', self.kb('status').stdout)
        self.kb('search', '--filter', 'absent', ok=False)
        self.assertEqual(self.head(), self.head(self.seed))

    def test_real_fuzzy_search_in_content_including_ignored_local_notes(self):
        self.network('offline')
        (self.wiki / 'Home.md').write_text('Configurer Docker hors connexion\n')
        (self.wiki / 'Privé.md').write_text('Docker non synchronisé\n')
        with (self.wiki / '.git/info/exclude').open('a') as stream:
            stream.write('\nPrivé.md\n')
        # Even a user's exact-match default must not turn kb into a literal search.
        self.env['FZF_DEFAULT_OPTS'] = '--exact'
        result = self.kb('search', '--filter', 'dckr')
        self.assertIn('Home.md:1:Configurer Docker', result.stdout)
        self.assertIn('Privé.md:1:Docker', result.stdout)
        self.kb('search', '--filter', '^Docker$', ok=False)
        self.assertEqual(self.head(), self.head(self.seed))

    def test_real_fuzzy_navigation_preserves_paths_and_empty_notes(self):
        folder = self.wiki / 'Réseau privé'
        folder.mkdir()
        name = 'Réseau privé/Été à Paris.md'
        (self.wiki / name).touch()
        (self.wiki / 'Home.md').write_text('Été à Paris mentioned in the content\n')
        self.assertEqual(self.kb('browse', '--filter', 'étprs').stdout, name + '\n')
        self.assertIn(name + ':1:', self.kb('search', '--filter', 'étprs').stdout)

    def test_content_browser_edits_refreshes_and_keeps_query(self):
        self.editor('Docker après modification\n')
        log = self.picker([('dckr', 'ctrl-e', 'Home.md'),
                           ('dckr', '', 'Home.md'), 130])
        result = self.kb('search')
        self.assertIn('Docker après modification', result.stdout)
        calls = [json.loads(line) for line in log.read_text().splitlines()]
        self.assertEqual(len(calls), 3)
        self.assertIn('Home.md:1:Docker après modification', calls[1]['input'])
        args = calls[1]['args']
        self.assertEqual(args[args.index('--query') + 1], 'dckr')
        self.assertEqual(self.head(), self.head(self.seed))

    def test_default_browser_and_optional_edit_and_read_paths(self):
        self.editor('Texte édité\n')
        log = self.picker([('', 'ctrl-e', 'Home.md'), 130])
        self.kb()
        self.assertEqual((self.wiki / 'Home.md').read_text(), 'Texte édité\n')
        self.assertEqual(len(log.read_text().splitlines()), 2)
        self.picker([('', '', 'Home.md')])
        self.assertEqual(self.kb('read', '--raw').stdout, 'Texte édité\n')
        self.editor('Encore édité\n')
        self.picker([('', '', 'Home.md')])
        self.kb('edit')
        self.assertEqual((self.wiki / 'Home.md').read_text(), 'Encore édité\n')

    def test_cancel_picker_without_mutation(self):
        for code in (1, 130):
            self.picker([code])
            self.kb('edit')
        self.assertEqual(self.git(self.wiki, 'status', '--porcelain').stdout, '')
        self.assertEqual((self.wiki / 'Home.md').read_text(), 'Welcome\n')

    def test_fuzzy_titles_return_real_paths_and_disambiguate_homonyms(self):
        names = ["Réseau privé/L'été [Paris]*.md", 'Autre nom.md']
        for name in names:
            path = self.wiki / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('# Guide VPN\n\nDocker hors connexion\n')
        matches = self.kb('browse', '--filter', 'gdvpn').stdout.splitlines()
        self.assertEqual(set(matches), set(names))
        matches = self.kb('search', '--filter', 'gdvpn').stdout.splitlines()
        self.assertTrue(any(name + ':3:Docker hors connexion' in matches for name in names))
        log = self.picker([('', '', names[0])])
        self.assertEqual(self.kb('read', '--raw').stdout, '# Guide VPN\n\nDocker hors connexion\n')
        rows = json.loads(log.read_text())['input'].splitlines()
        for name in names:
            self.assertIn(name + '\tGuide VPN — ' + name, rows)

    def test_guided_new_uses_editor_and_refuses_existing_or_invalid_paths(self):
        self.editor('# Nouvelle note\n')
        wiki = KB.Wiki(self.wiki)
        with patch.dict(os.environ, self.env, clear=True), patch('sys.stdin.isatty', return_value=True):
            with patch('builtins.input', return_value='Réseau privé/Été'):
                wiki.new()
                with self.assertRaises(KB.Error):
                    wiki.new()
            with patch('builtins.input', return_value='../échappée'):
                with self.assertRaises(KB.Error):
                    wiki.new()
        self.assertEqual(self.kb('read', 'Réseau privé/Été').stdout, '# Nouvelle note\n')
        self.assertFalse((self.base / 'échappée.md').exists())
        self.assertEqual(self.head(), self.head(self.seed))

    def test_guided_new_cancellation_and_noninteractive_error(self):
        wiki = KB.Wiki(self.wiki)
        with patch('sys.stdin.isatty', return_value=True):
            for answer in ('', '   '):
                with patch('builtins.input', return_value=answer):
                    wiki.new()
            with patch('builtins.input', side_effect=EOFError):
                wiki.new()
            with patch('builtins.input', side_effect=KeyboardInterrupt):
                with self.assertRaises(KeyboardInterrupt):
                    wiki.new()
        self.assertIn('kb new <path>', self.kb('new', ok=False).stderr)
        self.assertEqual(self.git(self.wiki, 'status', '--porcelain').stdout, '')

    def test_markdown_preview_width_unicode_and_raw_output(self):
        name = "Réseau privé/L'été [à Paris]*.md"
        path = self.wiki / name
        path.parent.mkdir()
        markdown = '# Titre\n\nDu **Markdown** à Paris.\n'
        path.write_text(markdown)
        binary = self.base / 'renderer-bin'
        binary.mkdir()
        args_file = self.base / 'renderer-args'
        program = binary / 'mdv'
        program.write_text('#!' + sys.executable + '\n' +
                           'import json, pathlib, sys\n' +
                           'pathlib.Path(' + repr(str(args_file)) + ').write_text(json.dumps(sys.argv[1:]))\n' +
                           'print("Rendered: " + sys.stdin.read())\n')
        program.chmod(0o755)
        self.env['PATH'] = str(binary) + os.pathsep + self.env['PATH']
        self.env['FZF_PREVIEW_COLUMNS'] = '55'
        self.assertIn('Rendered: # Titre', self.kb('read', '--preview', '--', name).stdout)
        self.assertEqual(json.loads(args_file.read_text()), ['-c', '55', '-'])
        args_file.unlink()
        self.assertEqual(self.kb('read', '--raw', name).stdout, markdown)
        self.assertEqual(self.kb('read', name).stdout, markdown)
        self.assertFalse(args_file.exists())
        # A renderer error must leave the note readable and unchanged.
        program.write_text('#!' + sys.executable + '\nraise SystemExit(1)\n')
        self.assertEqual(self.kb('read', '--preview', name).stdout, markdown)
        self.assertEqual(path.read_text(), markdown)

    def test_attachment_copy_offline_no_overwrite_and_limits(self):
        self.network('offline')
        source = self.base / 'schéma réseau.bin'
        source.write_bytes(b'\x00\xffattachment')
        self.kb('attach', source, 'réseau privé/schéma.bin')
        self.assertEqual((self.wiki / 'uploads/réseau privé/schéma.bin').read_bytes(), source.read_bytes())
        self.kb('attach', source, 'réseau privé/schéma.bin', ok=False)
        with source.open('wb') as stream:
            stream.truncate(KB.ATTACH_LIMIT + 1)
        self.assertIn('20 MiB', self.kb('attach', source, ok=False).stderr)

    def test_sync_only_wiki_preserves_identity(self):
        (self.wiki / 'Été.md').write_text('Bonjour\n')
        outside = self.base / 'outside.md'
        outside.write_text('Do not commit\n')
        self.kb('sync')
        self.assertEqual(self.head(), self.git(self.remote, 'rev-parse', 'main').stdout.strip())
        self.assertEqual(self.git(self.wiki, 'log', '-1', '--format=%an <%ae>').stdout.strip(),
                         'kb test <kb-test@example.invalid>')
        self.assertNotIn('outside.md', self.git(self.wiki, 'ls-files').stdout)
        self.assertIn('ahead: 0; behind: 0', self.kb('status').stdout)

    def test_unsafe_untracked_files_never_committed(self):
        (self.wiki / '.secret.md').write_text('secret')
        (self.wiki / '.DS_Store').write_text('metadata')
        (self.wiki / 'Thumbs.db').write_text('metadata')
        (self.wiki / 'link.md').symlink_to(self.seed / 'Home.md')
        (self.wiki / 'nested').symlink_to(self.seed, target_is_directory=True)
        executable = self.wiki / 'run.md'
        executable.write_text('script')
        executable.chmod(0o755)
        (self.wiki / 'web.config').write_text('configuration')
        (self.wiki / 'Safe.md').write_text('safe')
        self.kb('sync')
        self.assertEqual(set(self.git(self.wiki, 'ls-files').stdout.splitlines()), {'Home.md', 'Safe.md'})

    def test_invalid_staged_modes_and_hidden_content_block_sync(self):
        path = self.wiki / '.secret.md'
        path.write_text('secret')
        self.git(self.wiki, 'add', '-f', '.secret.md')
        self.assertIn('Unsupported', self.kb('sync', ok=False).stderr)
        self.assertEqual(self.head(), self.head(self.seed))

    def test_submodule_index_blocks_sync(self):
        self.git(self.wiki, 'update-index', '--add', '--cacheinfo', '160000', self.head(), 'module')
        self.assertIn('Unsupported', self.kb('sync', ok=False).stderr)

    def test_invalid_utf8_and_oversize_note_retained(self):
        path = self.wiki / 'Home.md'
        path.write_bytes(b'\xff')
        self.assertIn('UTF-8', self.kb('sync', ok=False).stderr)
        self.assertEqual(path.read_bytes(), b'\xff')
        path.write_bytes(b'a' * (KB.NOTE_LIMIT + 1))
        self.assertIn('1 MiB', self.kb('sync', ok=False).stderr)
        self.assertEqual(self.head(), self.head(self.seed))

    def test_editor_invalid_result_is_preserved(self):
        self.editor('a' * (KB.NOTE_LIMIT + 1))
        self.assertIn('1 MiB', self.kb('edit', 'Home', ok=False).stderr)
        self.assertEqual((self.wiki / 'Home.md').stat().st_size, KB.NOTE_LIMIT + 1)

    def test_paths_and_symlinks_cannot_escape(self):
        self.editor('no')
        for path in ('../escape', '/tmp/escape', 'uploads/../../escape', '.hidden/note'):
            self.kb('new', path, ok=False)
        (self.wiki / 'link').symlink_to(self.base, target_is_directory=True)
        self.kb('new', 'link/escape', ok=False)
        self.assertFalse((self.base / 'escape.md').exists())

    def test_tracked_executable_and_symlink_rejected(self):
        path = self.wiki / 'Home.md'
        path.chmod(0o755)
        self.kb('sync', ok=False)
        path.unlink()
        path.symlink_to(self.seed / 'Home.md')
        self.kb('sync', ok=False)

    def test_lock_refuses_concurrent_mutation(self):
        with (self.wiki / '.git/kb.lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertIn('Another kb', self.kb('sync', ok=False).stderr)
            self.kb('read', 'Home')

    def test_fast_forward_and_clean_merge(self):
        self.remote_change('Remote.md', b'Remote\n')
        self.kb('sync')
        self.assertTrue((self.wiki / 'Remote.md').exists())
        (self.wiki / 'Local.md').write_text('local')
        self.remote_change('Other.md', b'Other\n')
        self.kb('sync')
        self.assertEqual(len(self.git(self.wiki, 'rev-list', '--parents', '-1', 'HEAD').stdout.split()), 3)
        self.assertEqual(self.git(self.wiki, 'fsck').returncode, 0)

    def test_text_conflict_preserved_then_manual_resolution(self):
        (self.wiki / 'Home.md').write_text('Local\n')
        self.remote_change()
        result = self.kb('sync', ok=False)
        self.assertIn('merge --abort', result.stderr)
        self.assertIn('Home.md', result.stderr)
        self.assertTrue((self.wiki / '.git/MERGE_HEAD').exists())
        before = self.head()
        self.kb('sync', ok=False)
        self.assertEqual(self.head(), before)
        (self.wiki / 'Home.md').write_text('Reviewed both versions\n')
        self.git(self.wiki, 'add', 'Home.md')
        self.git(self.wiki, 'commit', '--no-edit')
        self.kb('sync')
        self.assertEqual(self.head(), self.git(self.remote, 'rev-parse', 'main').stdout.strip())

    def test_binary_conflict_retains_versions(self):
        self.remote_change('uploads/image.bin', b'\x00original')
        self.kb('sync')
        (self.wiki / 'uploads/image.bin').write_bytes(b'\x00local')
        self.remote_change('uploads/image.bin', b'\x00remote')
        self.kb('sync', ok=False)
        for stage, expected in ((1, b'\x00original'), (2, b'\x00local'), (3, b'\x00remote')):
            result = subprocess.run([REAL_GIT, '-C', str(self.wiki), 'show', f':{stage}:uploads/image.bin'],
                                    env=self.env, capture_output=True)
            self.assertEqual(result.stdout, expected)

    def test_modify_delete_conflict_retains_versions(self):
        (self.wiki / 'Home.md').write_text('Local edit\n')
        self.remote_change(data=None)
        self.kb('sync', ok=False)
        self.assertIn('Home.md', self.git(self.wiki, 'ls-files', '-u').stdout)
        self.assertEqual((self.wiki / 'Home.md').read_text(), 'Local edit\n')

    def test_auth_failure_retains_local_commit(self):
        (self.wiki / 'Local.md').write_text('pending')
        original = self.head()
        self.network('auth')
        self.assertIn('publickey', self.kb('sync', ok=False).stderr)
        self.assertNotEqual(self.head(), original)
        self.assertIn('ahead: 1', self.kb('status').stdout)

    def test_push_rejection_retains_commit(self):
        (self.wiki / 'Local.md').write_text('pending')
        self.network('reject')
        self.assertIn('Run kb sync again', self.kb('sync', ok=False).stderr)
        self.assertIn('ahead: 1', self.kb('status').stdout)

    def test_lost_push_ack_verified_by_reference(self):
        (self.wiki / 'Local.md').write_text('pending')
        self.network('lost-ack')
        self.assertIn('Publication confirmed', self.kb('sync').stdout)

    def test_unverifiable_publication_then_safe_retry(self):
        (self.wiki / 'Local.md').write_text('pending')
        self.network('unknown')
        self.assertIn('not confirmed', self.kb('sync', ok=False).stderr)
        revision = self.head()
        self.assertEqual(revision, self.git(self.remote, 'rev-parse', 'main').stdout.strip())
        self.env['PATH'] = os.environ['PATH']
        self.kb('sync')
        self.assertEqual(self.head(), revision)

    def test_remote_rewrite_refused(self):
        self.git(self.seed, 'checkout', '--orphan', 'replacement')
        self.git(self.seed, 'commit', '-am', 'Replacement history')
        self.git(self.seed, 'push', '--force', 'origin', 'HEAD:main')
        original = self.head()
        self.assertIn('rewritten', self.kb('sync', ok=False).stderr)
        self.assertEqual(self.head(), original)
        self.assertEqual(self.git(self.wiki, 'rev-parse', 'origin/main').stdout.strip(), original)
        self.assertIn('rewritten', self.kb('sync', ok=False).stderr)

    def test_remote_advances_between_fetch_and_push(self):
        (self.wiki / 'Local.md').write_text('pending')
        self.network('race')
        self.assertIn('not confirmed', self.kb('sync', ok=False).stderr)
        pending = self.head()
        self.env['PATH'] = os.environ['PATH']
        self.kb('sync')
        self.git(self.wiki, 'merge-base', '--is-ancestor', pending, 'HEAD')
        self.assertTrue((self.wiki / 'Concurrent.md').exists())
        self.assertTrue((self.wiki / 'Local.md').exists())

    def test_literal_pathspec_preserves_brackets_and_stars(self):
        name = 'Notes [privées]*.md'
        (self.wiki / name).write_text('literal filename')
        self.kb('sync')
        self.assertIn(name, self.git(self.wiki, '-c', 'core.quotePath=false', 'ls-files').stdout)

    def test_remote_unsupported_content_not_merged(self):
        self.remote_change('.hidden.md', b'invalid')
        original = self.head()
        self.kb('sync', ok=False)
        self.assertEqual(self.head(), original)
        self.assertFalse((self.wiki / '.hidden.md').exists())

    def test_merge_preserves_ignored_local_file(self):
        path = self.wiki / 'Pending.md'
        path.write_text('Local file to preserve')
        path.chmod(0o755)
        with (self.wiki / '.git/info/exclude').open('a') as stream:
            stream.write('\nPending.md\n')
        self.remote_change('Pending.md', b'Remote version\n')
        self.kb('sync', ok=False)
        self.assertEqual(path.read_text(), 'Local file to preserve')
        self.assertFalse((self.wiki / '.git/MERGE_HEAD').exists())

    def test_deletion_is_published(self):
        (self.wiki / 'Home.md').unlink()
        self.kb('sync')
        self.assertEqual(self.git(self.remote, 'ls-tree', '-r', 'main').stdout, '')

    def test_open_unicode_url_without_network(self):
        binary = self.base / 'bin'
        binary.mkdir()
        output = self.base / 'opened-url'
        for name in ('open', 'xdg-open'):
            program = binary / name
            program.write_text('#!' + sys.executable + '\nimport pathlib, sys\n' +
                               'pathlib.Path(' + repr(str(output)) + ').write_text(sys.argv[1])\n')
            program.chmod(0o755)
        self.env['PATH'] = str(binary) + os.pathsep + os.environ['PATH']
        self.kb('open', 'Réseau privé/Été.md')
        self.assertEqual(output.read_text(), 'https://wiki.nani/R%C3%A9seau%20priv%C3%A9/%C3%89t%C3%A9')


class ContentCompatibilityTests(unittest.TestCase):
    def test_note_titles_and_fallback_without_code_headings(self):
        for text, expected in [('# Titre à Paris ##\n', 'Titre à Paris'),
                               ('\nTitre Setext\n===\n', 'Titre Setext'),
                               ('```sh\n# Faux\n```\n# Vrai\n', 'Vrai'),
                               ('~~~sh\nFaux\n====\n~~~\n# Vrai\n', 'Vrai'),
                               ('    # Faux\n\n## Sous-titre\n', 'nom du fichier'),
                               ('# C#\n', 'C#'),
                               ('# Titre\tavec contrôle\n', 'Titre avec contrôle')]:
            with self.subTest(text=text):
                self.assertEqual(KB.note_title(text, 'nom du fichier'), expected)

    def test_size_boundaries_and_markdown_attachment(self):
        KB.validate_blob('Note.md', b'a' * KB.NOTE_LIMIT)
        KB.validate_blob('uploads/binary.md', b'\xff' * KB.ATTACH_LIMIT)
        with self.assertRaises(KB.Error):
            KB.validate_blob('uploads/binary.md', b'\xff' * (KB.ATTACH_LIMIT + 1))

    def test_server_path_restrictions(self):
        for name in ('custom.js', 'uploads/custom.css', 'uploads/math.config.js',
                     'uploads/config.rb', 'part//Note.md', './Note.md',
                     'colon:note.md', 'back\\slash.md', 'new\nline.md',
                     'a' * 1001 + '.md'):
            with self.subTest(name=name):
                self.assertFalse(KB.safe_name(name))


if __name__ == '__main__':
    unittest.main()
