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
