#!/usr/bin/env python3
"""
Live REPL - A dynamic terminal application to create dashboards with interactive REPL commands
Built with Python prompt_toolkit Application framework
"""

from prompt_toolkit.application import Application
from prompt_toolkit.layout.containers import HSplit, Window
from prompt_toolkit.layout.controls import FormattedTextControl, BufferControl
from prompt_toolkit.layout.layout import Layout
from prompt_toolkit.layout.processors import BeforeInput
from prompt_toolkit.buffer import Buffer
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.formatted_text import HTML, ANSI
from prompt_toolkit.history import InMemoryHistory
from termcolor import colored
from queue import Queue, Empty

import sys


class LiveREPL:
    """Main application class for the Live REPL terminal app"""
    def __init__(self, commands):
        self.commands = commands
        self.process_mode = "repl"
        self.output_text = ANSI("\n" * 9)
        self.dashboard_text = ANSI("")
        self.buffer = Buffer(history=InMemoryHistory(), enable_history_search=True, completer=None, multiline=False, accept_handler=self.process_command)
        self.prompt = BeforeInput("> ")
        self.setup_layout()
        self.setup_key_bindings()
        self.setup_application()

    def update_dashboard(self, new_content):
        """Update the dynamic content area with new text"""
        self.dashboard_text = ANSI(new_content)
        self.app.invalidate()

    def setup_layout(self):
        """Create the three-section horizontal split layout"""
        
        # Dashboard area for dynamic content (adapts to terminal size)
        self.dashboard_area = Window(
            content=FormattedTextControl(
                text=lambda: self.dashboard_text,
            ),
            wrap_lines=True,
        )
        
        # Separator line (1 line height) - dynamic width
        self.separator = Window(
            content=FormattedTextControl(
                text=self.get_separator_line
            ),
            height=1,
        )

        # REPL area for text input
        self.textinput_area = Window(
            content=BufferControl(
                buffer=self.buffer,
                input_processors=[self.prompt],
            ),
            height=1,
        )

        # Output area for command results (10 lines height)
        self.output_area = Window(
            content=FormattedTextControl(
                text=lambda: self.output_text
            ),
            height=10,
        )

        # Create the main layout with horizontal split
        self.layout = Layout(
            HSplit([
                self.dashboard_area,  # Dashboard area (dynamic)
                self.separator,       # Separator (1 line)
                self.output_area,     # Output area (10 lines)
                self.separator,       # Separator (1 line)
                self.textinput_area,  # REPL area (1 line)
            ])
        )
    
    def setup_key_bindings(self):
        """Setup key bindings for the application"""
        self.kb = KeyBindings()
        
        @self.kb.add('c-c')
        def _(event):
            """Cancel command on Ctrl+C"""
            if self.process_mode == "form":
                self.switch_mode()
            else:
                self.buffer.text = ""
                self.app.invalidate()
        
        @self.kb.add('c-q')
        def _(event):
            """Exit on Ctrl+Q"""
            event.app.exit()
    
    def setup_application(self):
        """Create the main application"""
        self.app = Application(
            layout=self.layout,
            key_bindings=self.kb,
            full_screen=True,
        )
    
    def process_command(self, buffer):
        if self.process_mode == "repl":
            return self.process_command_repl(buffer)
        else:
            return self.process_command_form(buffer)
    
    def process_command_repl(self, buffer):
        input = self.buffer.text.strip().split(' ')
        command = input[0]
        args = input[1:]
        if cmd in self.commands:
            self.command = self.commands[cmd]
            self.command_name = cmd
            if 'form' in self.command:
                self.buffer.append_to_history()
                self.switch_mode(self.command['form'])
                self.app.invalidate()
                return True
            else: 
                result = self.commands[cmd]['method'](*args)
        else:
            result = colored("Command not found", "red")

        self.output_text = ANSI("{}\n> {}\n{}".format(self.output_text.value.split('\n', 2)[-1], self.buffer.text, result))
        self.buffer.append_to_history()
        self.app.invalidate()  # Refresh the display
        return False

    def process_command_form(self, buffer):
    input = self.buffer.text.strip()
    self.answers[self.prompt.text.strip('> ').strip(' : ')] = input
    try:
        value, default = self.form_queue.get_nowait()
        self.prompt.text = "> {} : ".format(value)
        self.buffer.text = ""
        self.buffer.insert_text(default)
        self.app.invalidate()
        return True
    except Empty:
        result = self.command['method'](self.answers)
        self.output_text = ANSI("{}\n> {}\n{}".format(self.output_text.value.split('\n', 2)[-1], self.command_name, result))
        self.buffer.append_to_history()
        self.app.invalidate()
        self.switch_mode()
        return False
        
    def switch_mode(self, *args):
        if self.process_mode == "repl":
            self.last_prompt = self.prompt.text
            self.process_mode = "form"
            self.form_queue = Queue()
            
            for key, default in args[0].items():
                self.form_queue.put((key, default))
            value, default = self.form_queue.get()
            self.prompt.text = "> {} : ".format(value)
            self.buffer.text = ""
            self.buffer.insert_text(default)
            self.answers = {}
        elif self.process_mode == "form":
            self.prompt.text = self.last_prompt
            self.process_mode = "repl"
            self.form_queue = None
            self.send_form_method = None
            self.command_name = ""
            
            self.answers = {}

    def run(self):
        """Run the application"""
        try:
            self.app.run()
        except KeyboardInterrupt:
            pass
    
    def get_separator_line(self):
        """Generate separator line that adapts to terminal width"""
        try:
            # Get terminal width, default to 80 if not available
            import shutil

            width = shutil.get_terminal_size().columns
        except:
            width = 80
        
        return HTML("<ansicyan>" + "─" * width + "</ansicyan>")
