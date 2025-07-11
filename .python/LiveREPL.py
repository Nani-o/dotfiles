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

import sys


class LiveREPL:
    """Main application class for the Live REPL terminal app"""
    def __init__(self, commands):
        self.commands = commands
        self.output_text = ANSI("")
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
                self.textinput_area,  # REPL area (1 line)
                self.separator,       # Separator (1 line)
                self.output_area,     # Output area (10 lines)
            ])
        )
    
    def setup_key_bindings(self):
        """Setup key bindings for the application"""
        self.kb = KeyBindings()
        
        @self.kb.add('c-c')
        def _(event):
            """Exit on Ctrl+C"""
            event.app.exit()
        
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
        input = self.buffer.text.strip().split(' ')
        command = input[0]
        args = input[1:]
        if command in self.commands:
            result = self.commands[command](*args)
        else:
            result = colored("Command not found", "red")

        self.output_text = ANSI("> {}\n{}\n{}".format(self.buffer.text, result, self.output_text.value))
        self.buffer.append_to_history()
        # self.output_text = buffer.text + "\n" + self.output_text
        self.app.invalidate()  # Refresh the display
        return False

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
