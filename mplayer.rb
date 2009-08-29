=begin
   mplayer.rb

   <project_name> -- <project_description>

   Copyright (C) 2009
       Giuseppe Coviello <cjg@cruxppc.org>

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
=end

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
      while not @pipe.eof
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
      puts "mplayer closed retry te reinstantiate it"
      instantiate_mplayer if @playing
    end
  end
end
