#       rurora.rb
#
#       Copyright 2009 Unknown <cjg@blackout.cjg.home>
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.

require 'gtk2'
require 'mplayer'

class RubyRockRadio
	def initialize
		@mainwindow = Gtk::Window.new("Ruby Rock Radio")
		@mainwindow.signal_connect("destroy") { quit }
		@backend = MplayerBackend.new
		@backend.url = 'http://151.1.245.1/20'
		build_layout
		@backend.add_observer(self)
		@mainwindow.show_all
	end

	def quit
		@backend.stop
		Gtk.main_quit
	end

	def update(status)
		@status_label.text = status.gsub(/[^a-zA-Z0-9\.\,\:\ ]/, '').slice(0, 80).chomp
    end

	private
	def build_layout
		@mainwindow.border_width = 6
		main_box = Gtk::VBox.new(false, 12)

		main_box.pack_start(Gtk::ComboBox.new, false, false, 0)

		box1 = Gtk::HBox.new(true, 3)

		@play_button = Gtk::Button.new Gtk::Stock::MEDIA_PLAY
		@play_button.signal_connect("clicked") do
			@backend.play
			set_button
		end
		box1.pack_start(@play_button, false, false, 0)

		@pause_button = Gtk::Button.new Gtk::Stock::MEDIA_PAUSE
		@pause_button.signal_connect("clicked") do
			@backend.pause
			set_button
		end
		box1.pack_start(@pause_button, false, false, 0)

		@stop_button = Gtk::Button.new Gtk::Stock::MEDIA_STOP
		@stop_button.signal_connect("clicked") do
			@backend.stop
			set_button
		end
		box1.pack_start(@stop_button, false, false, 0)

		set_button

		button_box = Gtk::HBox.new(false, 6)
		@status_label = Gtk::Label.new 'Stopped'
		button_box.pack_start(@status_label, true, true, 0)
		button_box.pack_start(box1, false, false, 0)

		main_box.pack_start(button_box, false, false, 0)

		@mainwindow.add(main_box)
	end

	def set_button
		@play_button.sensitive = (not @backend.playing? or @backend.paused?)
		@pause_button.sensitive = (@backend.playing? and not @backend.paused?)
		@stop_button.sensitive = @backend.playing?
	end
end

class RadioStation
	attr_accessor :name, :url

	def initialize(name, url)
		@name = name
		@url = url
	end
end

RubyRockRadio.new
Gtk.main
