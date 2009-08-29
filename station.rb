#       station.rb
#
#       Copyright 2009 Giuseppe Coviello <cjg@cruxppc.org>
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

require 'observer'
require 'yaml'
require 'gtk2'

class RadioStation
	attr_accessor :name, :url

	def initialize(name, url)
		@name = name
		@url = url
	end

	def <=>(other)
		name <=> other.name
	end

	def ==(other)
		name == other.name
	end
end

class RadioStationLibrary
	include Observable

	def initialize(filename)
		@filename = filename
		begin
			@stations = File.open(@filename) { |yf| YAML::load( yf ) }
		rescue
			@stations = []
		end
	end

	def add(station)
		@stations.delete(station) if @stations.include?(station)
		@stations << station
		commit
	end

	def remove(station)
		@stations.delete(station)
		commit
	end

	def replace(station, other)
		@stations.delete(station)
		add(other)
	end

	def each
		@stations.each {|i| yield(i)} if block_given?
	end

	def [](key)
		if key.kind_of?(Integer)
			return @stations[key]
		end
		@stations.each do |x|
			return x if x.name == key
		end
		return nil
	end

  	private
	def commit
		File.open(@filename, 'w' ) do |out|
			YAML.dump(@stations, out)
		end
		changed
		notify_observers(self)
	end
end

class RadioStationLibraryComboBox < Gtk::ComboBox
	def initialize(library)
		super(true)
		library.add_observer(self)
		update(library)
	end

	def update(library)
		set_model(Gtk::ListStore.new(String))
		library.each {|x| append_text(x.name)}
	end
end

class RadioStationLibraryTreeView < Gtk::TreeView
	def initialize(library)
		super(nil)
		@library = library
		column = Gtk::TreeViewColumn.new("Radio Station")
		cell = Gtk::CellRendererText.new
		column.pack_start(cell, true)
		column.add_attribute(cell, 'text', 0)
		append_column(column)
		library.add_observer(self)
		update(library)
	end

	def update(library)
		m = Gtk::ListStore.new(String)
		library.each do |x|
			iter = m.append
			m.set_value(iter, 0, x.name)
		end
		set_model(m)
		self.selection.select_path(Gtk::TreePath.new('0')) unless selected
		signal_emit("cursor-changed")
	end

	def selected
		begin
			@library[self.selection.selected[0]]
		rescue
			nil
		end
	end
end

class RadioStationLibraryManager < Gtk::Window
	def initialize(library)
		super("Library Manager")

		@library = library
		build_layout
		signal_connect("delete-event") { false }
	end

	private
	def build_layout
		set_default_size(440, 260)
		@name_entry = Gtk::Entry.new
		@url_entry = Gtk::Entry.new
		@name_entry.sensitive = false
		@url_entry.sensitive = false

		self.border_width = 6
		paned = Gtk::HPaned.new

		library_box = Gtk::VBox.new(false, 12)
		@library_treeview = RadioStationLibraryTreeView.new(@library)
		@library_treeview.signal_connect("cursor-changed") do
			@editing = @library_treeview.selected
			if @editing
				@name_entry.text = @editing.name
				@url_entry.text = @editing.url
				@name_entry.sensitive = true
				@url_entry.sensitive = true
			else
				@name_entry.sensitive = false
				@url_entry.sensitive = false
			end
		end
		scrolledwindow = Gtk::ScrolledWindow.new
		scrolledwindow.add_with_viewport(@library_treeview)
		library_box.pack_start(scrolledwindow, true, true, 0)

		button_box = Gtk::VBox.new(true, 6)
		button = Gtk::Button.new Gtk::Stock::ADD
		button.signal_connect("clicked") do
			@editing = nil
			@name_entry.text = "Enter Radio Station Name"
			@url_entry.text = "Enter Radio Station URL"
			@name_entry.sensitive = true
			@url_entry.sensitive = true
		end
		button_box.pack_start(button, false, false, 0)

		button = Gtk::Button.new Gtk::Stock::REMOVE
		button.signal_connect("clicked") do
			@library.remove(@editing) if @editing
		end
		button_box.pack_start(button, false, false, 0)

		library_box.pack_start(button_box, false, false, 0)

		paned.pack1(library_box, true, false)

		edit_box = Gtk::HBox.new(false, 3)

		box = Gtk::VBox.new(true, 6)
		box.pack_start(Gtk::Label.new("Name:"), true, true, 0)
		box.pack_start(Gtk::Label.new("URL:"), true, true, 0)
		edit_box.pack_start(box, false, false, 0)

		box = Gtk::VBox.new(true, 6)
		box.pack_start(@name_entry, true, true, 0)
		box.pack_start(@url_entry, true, true, 0)
		edit_box.pack_start(box, true, true, 0)

		box1 = Gtk::HBox.new(true, 3)

		button = Gtk::Button.new Gtk::Stock::OK
		button.signal_connect("clicked") do
			station = RadioStation.new(@name_entry.text, @url_entry.text)
			if @editing
				@library.replace(@editing, station)
			else
				@library.add(station)
			end
			@editing = station
		end
		box1.pack_start(button, false, true, 0)

		button = Gtk::Button.new Gtk::Stock::CANCEL
		button.signal_connect("clicked") do
			@editing = @library_treeview.selected unless @editing
			if @editing
				@name_entry.text = @editing.name
				@url_entry.text = @editing.url
			else
			end
		end
		box1.pack_start(button, false, true, 0)

		button_box = Gtk::HBox.new(false, 6)
		button_box.pack_start(Gtk::Label.new, true, true, 0)
		button_box.pack_start(box1, false, false, 0)

		right_box = Gtk::VBox.new(false, 12)
		right_box.pack_start(edit_box, false, false, 0)
		right_box.pack_start(button_box, false, false, 0)
		right_box.pack_start(Gtk::Label.new, true, true, 0)

		paned.pack2(right_box, true, false)

		add(paned)
	end
end

if $0 == __FILE__
	RadioStationLibraryManager.new(RadioStationLibrary.new('rurora.library'))
	Gtk.main
end
