#       mplayer.rb
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

require 'tempfile'
require 'fifo'
require 'observer'

class MplayerBackend
	include Observable

	attr_reader :url
	attr_reader :status

	def initialize
		@url = ''
		@playing = false
		@paused = false
		@status = ''
	end

	def url=(stream_url)
		@url = stream_url
	end

	def play
		return if @playing and not @paused
		raise "Url not setted" if @url == ''
		if @paused
			@fifo.writeline('pause')
		else
			mkfifo
			instantiate_mplayer
		end
		@playing = true
		@paused = false
	end

	def pause
		return if @paused
		raise "Non playing" unless @playing
		begin
			@fifo.writeline('pause')
			@paused = true
		rescue
			p $ERROR_INFO
		end
	end

	def stop
		return unless @playing
		@fifo.writeline('stop')
		@playing = false
		@paused = false
	end

	def playing?
		@playing
	end

	def paused?
		@paused
	end

	private
	def mkfifo
		fifo = "#{Dir.tmpdir}/rurora-mplayer.#{Process.uid}"
		File.delete(fifo) if File.exist? fifo
		@fifo = Fifo.new(fifo, 'w')
	end

	def instantiate_mplayer
		@pipe = IO.popen("mplayer -cache 200 -input file=#{@fifo.filename} #{@url}")
		Thread.new do
			while true
				@status = @pipe.readline
				if @status =~ /Connecting to server/
					changed
					notify_observers('Connecting to server ...')
				elsif @status =~ /^Cache\ /
					changed
					notify_observers(@status)
				elsif @status =~ /title:\ /
					changed
					notify_observers($')
				end
			end
		end
		instantiate_mplayer if @playing
	end
end


