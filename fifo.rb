#       fifo.rb
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


class Fifo
	attr_reader :filename

	def initialize(filename, mode='r')
		@filename = filename
		@mode = mode
		`mkfifo #{@filename}`
		raise "Cannot create the Fifo on #{@filename}" unless $?.success?
	end

	def writeline(line)
		f = File.new(@filename, 'w')
		f.write("#{line}\n")
		f.close
	end
end

if $0 == __FILE__
	f = Fifo.new("test", 'w')
	p f
	f.open
end
