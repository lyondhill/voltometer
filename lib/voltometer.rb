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
    attr_accessor :names, :plants, :frames, :cells

    def initialize(watch_folder)
      log "watching: #{watch_folder}"
      self.watch_folder = watch_folder
      self.plants = {}
      self.frames = {}
      self.cells = {}
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
      log "starting listener"
      listener.start(false)
      log "listener started"
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

    # data looks like this time, "PlantName|FrameName|CellName"
    def insert_data(time, names, voltage)
      self.names = names
      insert_report(time, voltage)
    end

    def insert_report(time, voltage)
      moped[:reports].insert(_id: Moped::BSON::ObjectId.new, report_time: time, cell_id: cell_id, voltage: voltage.to_f)
    end

    def cell_id
      if id = self.cells[self.names]
        id
      else
        unless cell = moped[:cells].find(uid: cell_name, frame_id: frame_id).first
          moped[:cells].insert(uid: cell_name, _id: Moped::BSON::ObjectId.new, frame_id: frame_id)
          cell = moped[:cells].find(uid: cell_name).first
        end
        self.cells[self.names] = cell['_id']
      end
    end

    def frame_id
      if id = self.frames[self.names]
        id
      else
        unless frame = moped[:frames].find(name: frame_name, plant_id: plant_id).first
          moped[:frames].insert(name: frame_name, _id: Moped::BSON::ObjectId.new, plant_id: plant_id)
          frame = moped[:frames].find(name: frame_name).first
        end
        self.frames[self.names] = frame['_id']
      end
    end

    def plant_id
      if id = self.plants[self.names]
        id
      else
        unless @plant = moped[:plants].find(name: plant_name).first
          moped[:plants].insert(name: plant_name) 
          @plant = moped[:plants].find().first
        end
        self.plants[self.names] = @plant['_id']
      end
    end

    def plant_name
      self.names.split('|')[0]
    end

    def frame_name
      self.names.split('|')[1]
    end

    def cell_name
      self.names.split('|')[2]
    end

    def log(msg = nil)
      puts msg if ENV['DEVELOPMENT']
    end

  private

    def listener
      @listener ||= Listen.to(self.watch_folder, :filter => /\.(csv|CSV)$/)
      # @listener ||= Listen.to(self.watch_folder, :filter => /\.csv$/)
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
