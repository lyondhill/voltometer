require "voltometer/version"

require 'csv'
require 'time'

require 'moped'
require 'listen'

require 'pry'

module Voltometer
  class Monitor
    attr_accessor :watch_folder
    attr_accessor :active

    def initialize(watch_folder)
      self.watch_folder = watch_folder
      moped
      setup_listener
    end

    def setup_listener
      on_change do |modified, added, removed|
        modified.each {|file| file_modified(file)} if modified.any?
        added.each    {|file| file_added(file)}    if added.any?
        removed.each  {|file| file_removed(file)}  if removed.any?
      end
    end

    def start
      listener.start(false)
      self.active = true
      while self.active
        sleep(1)
      end
    end

    def stop
      self.active = false
      listener.stop
    end

    def file_modified(file)
      log "modified: #{file}"
      log `cat #{file}`
      log
    end

    def file_added(file)
      begin
        log "added: #{file}"
        CSV.foreach(file, headers: :first_row) do |row|
          row.each do |key, value|
            last_read_time(value) if key == "Timestamp"
            unless key == 'Timestamp' || key == 'TZ'
              log "#{last_read_time} Key: #{key}, Value: #{value}" 
              insert_data(last_read_time, key, value) 
            end
          end
        end
        remove_file(file)
        log
      rescue Exception => e
        log "ERROR #{e.inspect}"
        log e.backtrace.join("\n")
      end
    end

    def file_removed(file)
      log "removed: #{file}"
      log
    end

  protected

    def remove_file(file)
      log "removing #{file}"
      File.delete(file)
    end

    def last_read_time(time =  nil)
      if time
        @last_read_time = Time.parse(time)
      else
        @last_read_time
      end
    end

    def insert_data(time, frame_cell, voltage)
      frame_bson = frame_id(frame_cell.split('|').first)
      cell_bson = cell_id(frame_bson, frame_cell.split('|').last)
      insert_report(time, cell_bson, voltage)
    end

    def insert_report(time, cell_bson, voltage)
      moped[:reports].insert(_id: Moped::BSON::ObjectId.new, report_time: time, cell_id: cell_bson, voltage: voltage.to_f)
    end

    def cell_id(frame_bson, cell_name)
      unless cell = moped[:cells].find(:uid => cell_name).first
        moped[:cells].insert(uid: cell_name, _id: Moped::BSON::ObjectId.new, frame_id: frame_bson)
        cell = moped[:cells].find(uid: cell_name).first
      end
      cell['_id']
    end

    def frame_id(frame_name)
      unless frame = moped[:frames].find(:name => frame_name).first
        moped[:frames].insert(:name => frame_name, _id: Moped::BSON::ObjectId.new, plant_id: plant_id)
        frame ||= moped[:frames].find(:name => frame_name).first
      end
      frame['_id']
    end

    def plant_id
      if @plant
        @plant['_id']
      else
        unless @plant = moped[:plants].find().first
          moped[:plants].insert(name: '01') 
          @plant = moped[:plants].find().first
        end
        @plant['_id']
      end
    end

    def log(msg = nil)
      puts msg if ENV['DEVELOPMENT']
    end

  private

    def listener
      @listener ||= Listen.to(self.watch_folder, :filter => /\.csv$/)
    end

    def on_change(&block)
      listener.change(&block)
    end

    def moped(reconnect = false)
      if reconnect
        @session ||= ::Moped::Session.new([ "127.0.0.1:27017" ])
        @session.use( ENV['DEVELOPMENT'] ? 'voltrak_development' : 'voltrak_production')
        @session
      else
        @session ||= ::Moped::Session.new([ "127.0.0.1:27017" ])
        @session.use( ENV['DEVELOPMENT'] ? 'voltrak_development' : 'voltrak_production')
        @session
      end
    end


  end
end
