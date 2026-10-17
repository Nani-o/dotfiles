#!/usr/bin/env python3
"""Offline working copy for the private Gollum wiki (Python standard library only)."""
import argparse
import contextlib
import fcntl
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
from urllib.parse import quote

REMOTE = 'git@github.com:Nani-o/wiki.git'
WEB = 'https://wiki.nani'
NOTE_LIMIT = 1024 * 1024
ATTACH_LIMIT = 20 * NOTE_LIMIT
EXCLUDES = '\n# kb: local metadata only\n.*\n.DS_Store\nThumbs.db\nDesktop.ini\n__MACOSX/\n'


class Error(Exception):
    pass


def run(args, *, cwd=None, check=True, data=None):
    env = os.environ.copy()
    for key in ('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR',
                'GIT_OBJECT_DIRECTORY', 'GIT_ALTERNATE_OBJECT_DIRECTORIES'):
        env.pop(key, None)
    result = subprocess.run([str(a) for a in args], cwd=cwd, env=env,
                            input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and result.returncode:
        raise Error(result.stderr.decode('utf-8', 'replace').strip() or
                    'Command failed: ' + shlex.join(str(a) for a in args))
    return result


def safe_name(name):
    parts = name.split('/')
    return (bool(name) and len(name.encode('utf-8')) <= 1000 and
            not any(ord(c) < 32 or c in '\\:\x7f' for c in name) and
            all(p not in ('.', '..') and not p.startswith('.') for p in parts) and
            all(parts) and
            not any(p.lower() in ('thumbs.db', 'desktop.ini', '__macosx', 'web.config',
                                     'custom.js', 'custom.css', 'math.config.js', 'config.rb')
                    for p in parts))


def validate_blob(name, data):
    if not safe_name(name):
        raise Error(f'Unsupported content path: {name!r}')
    if name.startswith('uploads/'):
        if len(data) > ATTACH_LIMIT:
            raise Error(f'Attachment exceeds 20 MiB: {name}')
    elif name.endswith('.md'):
        if len(data) > NOTE_LIMIT:
            raise Error(f'Note exceeds 1 MiB: {name}')
        try:
            data.decode('utf-8')
        except UnicodeDecodeError as exc:
            raise Error(f'Note must be UTF-8: {name}') from exc
    else:
        raise Error(f'Non-Markdown files must be below uploads/: {name}')


def display_text(text):
    return ''.join(c if c.isprintable() else ' ' for c in text)


def note_title(text, fallback):
    """Find an ATX or Setext H1, excluding fenced and indented code."""
    fence = None
    previous = ''
    for line in text.splitlines():
        marker = re.match(r' {0,3}(`{3,}|~{3,})(.*)$', line)
        if fence:
            if (marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence)
                    and not marker[2].strip()):
                fence = None
            continue
        if marker:
            fence = marker[1]
            previous = ''
            continue
        if line.startswith(('    ', '\t')):
            previous = ''
            continue
        heading = re.fullmatch(r' {0,3}#(?:[ \t]+(.*))?', line)
        if heading:
            title = re.sub(r'[ \t]+#+[ \t]*$', '', heading[1] or '').strip()
            if title:
                return display_text(title)
        if previous and re.fullmatch(r' {0,3}=+[ \t]*', line):
            return display_text(previous)
        previous = line.strip()
    return display_text(fallback)


class Wiki:
    def __init__(self, directory=None):
        raw = Path(directory or os.environ.get('KB_DIR', '~/.local/share/homelab/wiki')).expanduser()
        if raw.is_symlink():
            raise Error('KB_DIR must not be a symbolic link')
        self.root = raw.resolve()
        dotfiles = Path(__file__).resolve().parent.parent
        if self.root == dotfiles or dotfiles in self.root.parents or self.root in dotfiles.parents:
            raise Error('The wiki must be independent of the dotfiles repository')

    def git(self, *args, check=True, data=None):
        return run(['git', '--literal-pathspecs', '-c', 'core.quotePath=false',
                    '-C', self.root, *args], check=check, data=data)

    def value(self, *args):
        return self.git(*args).stdout.decode('utf-8').strip()

    def require(self):
        if not (self.root / '.git').is_dir() or (self.root / '.git').is_symlink():
            raise Error('No independent wiki clone; run kb init')
        if Path(self.value('rev-parse', '--show-toplevel')).resolve() != self.root:
            raise Error('KB_DIR is not the repository root')
        if self.value('rev-parse', '--is-shallow-repository') != 'false':
            raise Error('A full clone is required')
        if self.value('symbolic-ref', '--short', 'HEAD') != 'main':
            raise Error('The wiki must be on branch main')

    @contextlib.contextmanager
    def lock(self, initializing=False):
        if initializing:
            self.root.parent.mkdir(parents=True, exist_ok=True)
            path = self.root.parent / ('.' + self.root.name + '.kb-init.lock')
        else:
            self.require()
            path = self.root / '.git' / 'kb.lock'
        fd = os.open(path, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        try:
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as exc:
                raise Error('Another kb mutation is running') from exc
            yield
        finally:
            os.close(fd)

    def excludes(self):
        path = self.root / '.git/info/exclude'
        previous = path.read_text() if path.exists() else ''
        if EXCLUDES not in previous:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(previous + EXCLUDES)

    def init(self, remote):
        with self.lock(initializing=True):
            if self.root.exists():
                raise Error('KB_DIR already exists; refusing to replace it')
            temp = Path(tempfile.mkdtemp(prefix='.kb-clone-', dir=self.root.parent))
            try:
                run(['git', 'clone', '--origin', 'origin', '--branch', 'main', '--', remote, temp])
                temp.rename(self.root)
            finally:
                if temp.exists():
                    shutil.rmtree(temp)
            self.require()
            self.excludes()
            self.validate_tree('HEAD')
            print(f'Full wiki clone ready: {self.root}')

    def path(self, name, note=False):
        if note and not name.endswith('.md'):
            name += '.md'
        if not safe_name(name):
            raise Error(f'Invalid relative path: {name!r}')
        if note and name.startswith('uploads/'):
            raise Error('Notes cannot be stored below uploads/')
        path = self.root / name
        current = self.root
        for part in PurePosixPath(name).parts:
            current = current / part
            if current.is_symlink():
                raise Error(f'Symbolic links are excluded: {name}')
        if not path.resolve().is_relative_to(self.root):
            raise Error('Path escapes the wiki')
        return path

    def files(self):
        for directory, dirs, files in os.walk(self.root, followlinks=False):
            dirs[:] = sorted(d for d in dirs if safe_name(d) and
                             not (Path(directory) / d).is_symlink())
            for filename in sorted(files):
                path = Path(directory) / filename
                name = path.relative_to(self.root).as_posix()
                if safe_name(name) and stat.S_ISREG(path.lstat().st_mode) and not path.stat().st_mode & 0o111:
                    yield name, path

    def validate_tree(self, ref=None):
        if ref is None:
            entries = self.git('ls-files', '--stage', '-z').stdout.split(b'\0')
        else:
            entries = self.git('ls-tree', '-rz', ref).stdout.split(b'\0')
        for entry in entries:
            if not entry:
                continue
            meta, raw_name = entry.split(b'\t', 1)
            mode, middle, last = meta.split()
            oid = middle if ref is None else last
            if mode != b'100644' or (ref is None and last != b'0'):
                raise Error('Unsupported file mode or unresolved conflict: ' + os.fsdecode(raw_name))
            name = os.fsdecode(raw_name)
            size = int(self.value('cat-file', '-s', oid.decode()))
            limit = NOTE_LIMIT if name.endswith('.md') and not name.startswith('uploads/') else ATTACH_LIMIT
            if size > limit:
                raise Error(f'Content exceeds size limit: {name}')
            validate_blob(name, self.git('cat-file', 'blob', oid.decode()).stdout)

    def conflict(self):
        if (self.root / '.git/MERGE_HEAD').exists() or self.git('ls-files', '-u').stdout:
            prefix = 'git -C ' + shlex.quote(str(self.root))
            files = self.value('diff', '--name-only', '--diff-filter=U')
            raise Error('Merge in progress; versions and merge state retained.\n' + files +
                        '\nReview and resolve, then: ' + prefix + ' add -- <paths>; ' +
                        prefix + ' commit\nOr explicitly abandon: ' + prefix + ' merge --abort')

    def edit(self, name, new=False):
        with self.lock():
            self.conflict()
            path = self.path(name, note=True)
            if new and path.exists():
                raise Error('Note already exists')
            if not new and not path.is_file():
                raise Error('Note does not exist')
            editor = os.environ.get('EDITOR')
            if not editor:
                raise Error('Set EDITOR first (for example: nano or code --wait)')
            command = [editor] if Path(editor).is_file() else shlex.split(editor)
            if not command:
                raise Error('EDITOR is empty')
            if Path(command[0]).name in ('code', 'code-insiders') and not any(a in command for a in ('--wait', '-w')):
                command.append('--wait')
            path.parent.mkdir(parents=True, exist_ok=True)
            if new:
                path.touch(exist_ok=False)
            result = subprocess.run([*command, str(path)])
            if result.returncode:
                raise Error('Editor failed; local content retained')
            self.path(name, note=True)
            if not path.is_file() or path.stat().st_mode & 0o111:
                raise Error('Edited note must be an ordinary non-executable file')
            validate_blob(path.relative_to(self.root).as_posix(), path.read_bytes())
            print('Saved locally; use kb sync to publish.')

    def new(self, name=None):
        if name is None:
            if not sys.stdin.isatty():
                raise Error('A note path is required without a terminal: kb new <path>')
            try:
                name = input('Nouvelle note (chemin relatif) : ')
            except EOFError:
                print()
                return
            if not name.strip():
                return
        self.edit(name, new=True)

    def attach(self, source, destination):
        with self.lock():
            self.conflict()
            source = Path(source).expanduser()
            if source.is_symlink() or not source.is_file() or source.stat().st_mode & 0o111:
                raise Error('Attachment must be an ordinary non-executable file')
            if source.stat().st_size > ATTACH_LIMIT:
                raise Error('Attachment exceeds 20 MiB')
            name = 'uploads/' + (destination or source.name)
            target = self.path(name)
            data = source.read_bytes()
            validate_blob(name, data)
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open('xb') as stream:
                stream.write(data)
            print(f'[{target.name}]({quote(name, safe="/")})')

    def read(self, name, raw=False, preview=False):
        path = self.path(name, note=True)
        if not path.is_file() or path.stat().st_mode & 0o111:
            raise Error('Note must be an ordinary non-executable file')
        data = path.read_bytes()
        validate_blob(path.relative_to(self.root).as_posix(), data)
        terminal = sys.stdout.isatty()
        if not raw and (preview or terminal) and shutil.which('mdv'):
            width = shutil.get_terminal_size().columns
            if preview:
                width = int(os.environ.get('FZF_PREVIEW_COLUMNS', width))
            rendered = run(['mdv', '-c', str(max(20, width)), '-'], data=data, check=False)
            if rendered.returncode == 0:
                data = rendered.stdout
        if terminal and not preview and not raw and shutil.which('less'):
            subprocess.run(['less', '-R'], input=data, check=True)
        else:
            sys.stdout.write(data.decode('utf-8'))

    def candidates(self, content=False):
        # Walk the working tree, including ignored and untracked local notes.
        for name, path in self.files():
            if not name.endswith('.md') or name.startswith('uploads/'):
                continue
            text = ''
            if path.stat().st_size <= NOTE_LIMIT:
                text = path.read_bytes().decode('utf-8', 'replace')
            title = note_title(text, path.stem.replace('_', ' '))
            label = f'{title} — {name}'
            if not content:
                yield name, label, name
                continue
            for number, line in enumerate(text.splitlines() or [''], 1):
                # Keep terminal controls out of the list, without changing the note.
                snippet = display_text(line)
                yield name, f'{label}:{number}:{snippet}', f'{name}:{number}:{snippet}'

    def browse(self, query='', content=False, filter_only=False, action='read',
               loop=True, raw=False):
        if not shutil.which('fzf'):
            raise Error('Required executable missing: fzf (install it with brew install fzf)')
        preview = shlex.join(['env', 'KB_DIR=' + str(self.root), sys.executable,
                              str(Path(__file__).resolve()), 'read', '--preview', '--'])
        preview += ' {s1}'
        while True:
            # The hidden field keeps identity independent of the displayed title.
            entries = {name + '\t' + label: (name, plain)
                       for name, label, plain in self.candidates(content)}
            command = ['fzf', '--no-exact', '--no-multi', '--layout=reverse',
                       '--delimiter', '\t', '--with-nth', '2..', '--query', query]
            if filter_only:
                command += ['--filter', query]
            else:
                if not entries:
                    print('No local notes yet; create one with kb new <path>.')
                    return 0
                command += ['--print-query', '--expect', 'ctrl-e,ctrl-o',
                            '--prompt', 'Content > ' if content else 'Notes > ',
                            '--header', 'Enter: ' + action + ' | Ctrl-E: edit | Ctrl-O: web | Esc: quit',
                            '--preview', preview,
                            '--preview-window', 'right,70%,wrap,<100(down,75%,wrap)',
                            '--bind', 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up']
            data = ''.join(entry + '\n' for entry in entries).encode('utf-8')
            result = run(command, cwd=self.root, data=data, check=False)
            if filter_only:
                if result.returncode not in (0, 1):
                    raise Error(result.stderr.decode('utf-8', 'replace').strip())
                for selected in result.stdout.decode('utf-8').split('\n'):
                    if selected:
                        if selected not in entries:
                            raise Error('fzf returned an unknown note')
                        sys.stdout.write(entries[selected][1] + '\n')
                return result.returncode
            if result.returncode in (1, 130):
                return 0
            if result.returncode:
                raise Error(result.stderr.decode('utf-8', 'replace').strip() or 'fzf failed')
            fields = result.stdout.decode('utf-8').split('\n')
            if len(fields) < 3:
                return 0
            query, key, selected = fields[:3]
            if selected not in entries:
                raise Error('fzf returned an unknown note')
            name = entries[selected][0]
            chosen_action = {'ctrl-e': 'edit', 'ctrl-o': 'open'}.get(key, action)
            if chosen_action == 'edit':
                self.edit(name)
            elif chosen_action == 'open':
                self.open(name)
            else:
                self.read(name, raw=raw)
            if not loop:
                return 0

    def open(self, name='Home.md'):
        self.path(name, note=True)
        if name.endswith('.md'):
            name = name[:-3]
        url = WEB + '/' + quote(name, safe='/')
        subprocess.run(['open' if sys.platform == 'darwin' else 'xdg-open', url], check=True)

    def status(self):
        print(self.value('status', '--short'))
        known = self.git('rev-parse', '--verify', 'refs/remotes/origin/main', check=False)
        if known.returncode == 0:
            behind, ahead = self.value('rev-list', '--left-right', '--count',
                                      'origin/main...HEAD').split()
            print(f'Last known origin/main: {known.stdout.decode().strip()}')
            print(f'Local commits ahead: {ahead}; behind: {behind}')
        else:
            print('No known origin/main reference')
        print('Current remote state unknown: status does not access the network.')
        if (self.root / '.git/MERGE_HEAD').exists():
            print('Merge in progress; run kb sync for recovery commands.')

    def sync(self):
        with self.lock():
            self.conflict()
            self.excludes()
            self.validate_tree()
            tracked = set(os.fsdecode(p) for p in self.git('ls-files', '-z').stdout.split(b'\0') if p)
            untracked = set(os.fsdecode(p) for p in self.git(
                'ls-files', '--others', '--exclude-standard', '-z').stdout.split(b'\0') if p)
            eligible = tracked | untracked
            candidates = []
            for name, path in self.files():
                if name not in eligible:
                    continue
                limit = ATTACH_LIMIT if name.startswith('uploads/') else NOTE_LIMIT
                if path.stat().st_size > limit:
                    raise Error(f'Content exceeds {limit // NOTE_LIMIT} MiB: {name}')
                validate_blob(name, path.read_bytes())
                candidates.append(name)
            for name in tracked:
                path = self.path(name)
                if path.exists() and (not path.is_file() or path.stat().st_mode & 0o111):
                    raise Error(f'Unsupported tracked content: {name}')
                if not path.exists():
                    candidates.append(name)
            # Only explicit validated wiki paths, never git add .
            for offset in range(0, len(candidates), 100):
                self.git('add', '--all', '--', *candidates[offset:offset + 100])
            self.validate_tree()
            if self.git('diff', '--cached', '--quiet', check=False).returncode:
                self.git('commit', '-m', 'Update wiki via kb')
            old = self.git('rev-parse', '--verify', 'refs/remotes/origin/main', check=False)
            # An empty refmap prevents fetch from opportunistically replacing
            # origin/main before the history-rewrite check has passed.
            self.git('fetch', '--no-tags', '--refmap=', 'origin', 'refs/heads/main')
            fetched = self.value('rev-parse', 'FETCH_HEAD')
            if old.returncode == 0 and self.git('merge-base', '--is-ancestor',
                                               old.stdout.decode().strip(), fetched, check=False).returncode:
                raise Error('Remote history was rewritten; retained all local commits. Review manually.')
            self.validate_tree(fetched)
            self.git('update-ref', 'refs/remotes/origin/main', fetched)
            result = self.git('merge', '--no-edit', '--no-commit', '--no-overwrite-ignore',
                              fetched, check=False)
            if result.returncode:
                self.conflict()
                raise Error(result.stderr.decode('utf-8', 'replace') + result.stdout.decode('utf-8', 'replace'))
            self.validate_tree()
            if (self.root / '.git/MERGE_HEAD').exists():
                self.git('commit', '--no-edit')
            revision = self.value('rev-parse', 'HEAD')
            push = self.git('push', 'origin', 'HEAD:refs/heads/main', check=False)
            confirmation = self.git('ls-remote', '--exit-code', 'origin', 'refs/heads/main', check=False)
            if confirmation.returncode == 0 and confirmation.stdout.split()[0].decode() == revision:
                self.git('update-ref', 'refs/remotes/origin/main', revision)
                print(f'Publication confirmed on origin/main: {revision}')
            else:
                detail = push.stderr.decode('utf-8', 'replace').strip()
                raise Error(f'Publication not confirmed; all commits retained. Run kb sync again.\n{detail}')


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     epilog='Without a command, open the fuzzy note browser. '
                                            'Enter reads; Ctrl-E edits; Ctrl-O opens the web page.')
    commands = parser.add_subparsers(dest='command')
    init = commands.add_parser('init', help='Create a full independent clone')
    init.add_argument('--remote', default=REMOTE)
    for name, description in (('browse', 'Fuzzy navigation by note title and path (default)'),
                              ('search', 'Fuzzy search in local titles, paths and content')):
        command = commands.add_parser(name, help=description)
        command.add_argument('query', nargs='?', default='')
        command.add_argument('--filter', action='store_true', help='Print fuzzy matches without opening fzf')
    for name in ('read', 'new', 'edit'):
        command = commands.add_parser(name)
        command.add_argument('path', nargs='?')
        if name == 'read':
            command.add_argument('--raw', action='store_true', help='Print the original Markdown')
            command.add_argument('--preview', action='store_true', help=argparse.SUPPRESS)
    attach = commands.add_parser('attach')
    attach.add_argument('source')
    attach.add_argument('destination', nargs='?')
    commands.add_parser('status')
    commands.add_parser('sync')
    browser = commands.add_parser('open')
    browser.add_argument('path', nargs='?')
    args = parser.parse_args()
    try:
        if not shutil.which('git'):
            raise Error('Required executable missing: git')
        wiki = Wiki()
        if args.command == 'init':
            wiki.init(args.remote)
        elif args.command == 'open':
            wiki.open(args.path or 'Home.md')
        elif args.command == 'read' and args.preview:
            if not args.path:
                raise Error('A preview needs a note path')
            wiki.read(args.path, preview=True)
        else:
            wiki.require()
            if args.command is None:
                return wiki.browse()
            if args.command in ('browse', 'search'):
                return wiki.browse(args.query, content=args.command == 'search', filter_only=args.filter)
            if args.command == 'read':
                if args.path:
                    wiki.read(args.path, raw=args.raw)
                else:
                    return wiki.browse(loop=False, raw=args.raw)
            elif args.command == 'new':
                wiki.new(args.path)
            elif args.command == 'edit':
                if args.path:
                    wiki.edit(args.path)
                else:
                    return wiki.browse(action='edit', loop=False)
            elif args.command == 'attach':
                wiki.attach(args.source, args.destination)
            elif args.command == 'status':
                wiki.status()
            elif args.command == 'sync':
                wiki.sync()
    except (Error, OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f'kb: {exc}', file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('kb: interrupted; local content retained. Inspect kb status before retrying.', file=sys.stderr)
        return 130
    return 0


if __name__ == '__main__':
    sys.exit(main())
