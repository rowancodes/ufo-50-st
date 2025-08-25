# UFO 50 Save Tool (or LX-III Save Tool)
# made by rowancodes
# ---------------------
# UFO 50 is a video game by Mossmouth, LLC @ https://50games.fun/

require 'base64'
require 'json'
require 'fileutils'
require 'date'
require 'readline'

require_relative 'src/game_index'
require_relative 'src/validate_parameters'
require_relative 'src/block_koala'

OPTIONAL_PARAMS = { output: nil, no_verify: false, overwrite: false, verbose: false, validate_bk: true }

SAVE_INDEX = {
  "1": nil,
  "2": nil,
  "3": nil
}

class SaveFile
  def initialize(slot: nil, disk_path: nil)
    @slot = slot
    @raw_save_data = nil
    @indexed_save_data = nil
    @filtered_save_data = nil
    @disk_path = disk_path
  end

  attr_accessor :slot, :raw_save_data, :indexed_save_data, :filtered_save_data, :disk_path

  class << self
    def find_or_create_slot(slot_num)
      indexed = SAVE_INDEX[slot_num]
      return indexed unless indexed.nil?

      debug(m: "Creating object: SaveFile ##{slot_num}")
      SAVE_INDEX[slot_num] = new(slot: slot_num)
    end

    def create_from_disk(disk_path)
      debug(m: "Creating object: SaveFile for disk #{disk_path}")
      new(disk_path: disk_path)
    end

    def filepath_for_slot(slot_num)
      game_saves_location = "#{ENV['LOCALAPPDATA']}\\ufo50\\"

      "#{game_saves_location}save#{slot_num}.ufo"
    end

    def encode_data(game_data)
      end_char = "\u0000".force_encoding('UTF-8')

      (Base64.encode64(game_data.force_encoding('UTF-8')).delete("\n") + end_char).force_encoding('UTF-8')
    end

    def decode_file(filepath)
      input = File.open(filepath, 'r:utf-8')

      Base64.decode64(input.readline.force_encoding('UTF-8')).force_encoding('UTF-8')
    end
  end

  def filepath(folder: false)
    return disk_path if disk_path

    game_saves_location = "#{ENV['LOCALAPPDATA']}\\ufo50\\"
    return game_saves_location if folder == true

    "#{game_saves_location}save#{@slot}.ufo"
  end

  def raw_save_data
    @raw_save_data ||= self.class.decode_file(filepath)
  end

  def indexed_save_data
    @indexed_save_data ||= build_save_data_index
  end

  def get_matching_pairs(unparsed_json, regex)
    data = JSON.parse(unparsed_json)

    search = lambda do |obj, result = {}|
      case obj
      when Hash
        obj.each do |k, v|
          result[k] = v if k.match(regex)
          search.call(v, result)
        end
      when Array
        obj.each { |item| search.call(item, result) }
      end
      result
    end

    search.call(data)
  end

  def build_save_data_index
    debug(m: "Building save data index for Save #{@slot}")

    index = {}

    (0..50).each do |game_num|
      internal_id = GAME_INDEX[game_num.to_s.to_sym][:id]
      regex = /\bgame#{internal_id}[^0-9][\a-z]+|game0+[\a-z][^0-9]+#{internal_id}\b/
      search = get_matching_pairs(raw_save_data, regex)
      index[game_num] = search unless search.empty?
    end

    index
  end

  # filter out any save info not to copy
  def filtered_data
    return @filtered_save_data unless @filtered_save_data.nil? || @filtered_save_data.empty?

    debug(m: "Generating filtered data for slot #{@slot} because it was nil or empty")
    filtered_terms = [
      'profileLanguage',   # don't copy someones language settings
      'game0_libraryBG',   # don't copy bg
      'randSortOrder',     # saves track random sort order
      'HS NAME PREV',      # hiscores previous input
      '18_customLevel'     # do not export BK custom levels unless explicitly stated
    ]

    @filtered_save_data = indexed_save_data.transform_values do |hash|
      hash.reject { |k, _| filtered_terms.any? { |term| k.include?(term) } }
    end
  end

  def search_for(game_list)
    internal_ids = game_list.map { |num| GAME_INDEX[num.to_s.to_sym][:id] }
    search = filtered_data.slice(0, *game_list.map(&:to_i))
    search[0] = search[0].select { |k, _v| k.match(/(?<!\d)(#{internal_ids.map(&:to_i).join('|')})\z/) } if search[0]
    search
  end

  def force_indexing
    indexed_save_data unless disk_path
  end

  def reindex(new_raw_save_data)
    debug(m: "Reindexing save data for slot #{@slot}")
    @indexed_save_data&.clear
    @filtered_save_data&.clear
    @raw_save_data = new_raw_save_data
    @indexed_save_data = build_save_data_index
    @filtered_save_data = filtered_data
  end

  def profile_name
    name = JSON.parse(raw_save_data).select { |key| key.include?('game0_profileName') }
    name.nil? ? 'EXPORT' : name['game0_profileName'].to_s
  end

  def disk_export_filename(game_list, bk_data: nil)
    prefix = !bk_data.nil? ? "BK-CUSTOM#{slot}" : "#{profile_name}"
    if OPTIONAL_PARAMS[:output]
      "#{OPTIONAL_PARAMS[:output].split('.').first}.ufodisk"
    else
      "#{prefix}-#{game_list.join('-')}-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.ufodisk"
    end
  end
end

def get_help(logo: true)
  puts
  puts_logo if logo == true

  commands = [
    ['help',    'displays this information'],
    ['view',    'view game data for slot'],
    ['copy',    'copy games from one save to another'],
    ['export',  "exports games to a .ufodisk file\n\t\t\t to share w/ your friends :3"],
    ['import',  'displays import help'],
    ['delete',  'deletes game data for slot'],
    ['goals',   'show goals for games'],
    ['list',    'list ufosoft games'],
    ['exit',    'closes the program']
  ]

  params = [
    ['-slot',   'source save slot [1/2/3]'],
    ['-to',     'destination save slot [1/2/3]'],
    ['-games',  'list of games to copy/export'],
    ['-bk',     "for export/import/view of block\n\t\t\t koala custom levels"]
  ]

  optional = [
    ['--output',     'specify an output filename'],
    ['--no-verify',  "does not verify game choice\n\t\t\t before continuing (be careful!)"],
    ['--overwrite',  "overwrites existing game data\n\t\t\t without asking (be careful!)"]
  ]

  puts 'Usage:'
  commands.each { |cmd, desc| puts "\t#{cmd.ljust(8)}=>\t#{desc}" unless cmd.empty? || desc.empty? }
  puts 'Params:'
  params.each { |param, desc| puts "\t#{param.ljust(10)}=>\t#{desc}" unless param.empty? || desc.empty? }
  puts 'Optional:'
  optional.each { |opt, desc| puts "\t#{opt.ljust(12)}=>\t#{desc}" unless opt.empty? || desc.empty? }

  puts 'v1.2.0'
end

def puts_logo
  puts '==========================================================='
  puts ':::        :::    :::   ::::::::::: ::::::::::: :::::::::::'
  puts ':+:        :+:    :+:       :+:         :+:         :+:    '
  puts '+:+         +:+  +:+        +:+         +:+         +:+    '
  puts '+#+          +#++:+  +#+    +#+         +#+         +#+    '
  puts '+#+         +#+  +#+        +#+         +#+         +#+    '
  puts '#+#        #+#    #+#       #+#         #+#         #+#    '
  puts '########## ###    ###   ########### ########### ###########'
  puts "\t\t\tSAVE TOOL !"
  puts '==========================================================='
  puts "\t\t  PLEASE CLOSE YOUR GAME!"
end

def puts_disk_detected
  puts ' _.........._ '
  puts '||          ||'
  puts '||   UFO    ||'
  puts '||   DISK   ||'
  puts '||          ||'
  puts '||__________||'
  puts '|   ______   |'
  puts '|__|____|_|__|'
  puts
  puts '.ufodisk detected!'
  puts
end

def get_user_input
  input = Readline.readline('>> ', true)
  input.gsub!(/[^a-zA-Z0-9\-,._ ]+[a-zA-Z]/, '')
  input.downcase
end

def fail_with_reason(reason: 'FailureUnknown', error: true)
  error ? (print '!! ERROR: ') : (print '!! ')
  puts reason
  true
end

def debug(m: '???')
  puts "DEBUG: #{m}" if OPTIONAL_PARAMS[:verbose]
end

def validate_parameters(params)
  pv = ValidateParameters.new
  params = params.split(' ')
  return if params.empty?

  set_optional_params(params)
  command = params.first

  handlers = {
    'help' => -> { get_help },
    'copy' => -> { handle_copy(params, pv) },
    'export' => -> { handle_export(params, pv) },
    'import' => -> { display_import_help },
    'list' => -> { print_games_to_screen },
    'view' => -> { handle_view(params, pv) },
    'goals' => -> { handle_goals(params, pv) },
    'delete' => -> { handle_delete(params, pv) },
    'exit' => -> { handle_exit },
    'quit' => -> { handle_exit }
  }

  if handlers.key?(command)
    handlers[command].call
  else
    fail_with_reason(reason: "?? Unknown command: #{command}", error: false)
  end
end

def handle_exit
  puts 'bye bye :3'
  exit
end

def handle_copy(params, pv)
  return if pv.missing_or_no_params?(params, 7, [%w[-slot -to -games]],
                                     reason: 'Usage: copy -slot [1/2/3] -to [1/2/3] -games 1,13,27')

  game_val = params[params.index('-games') + 1]&.split(',')&.uniq
  slot_val = params[params.index('-slot') + 1]
  to_val = params[params.index('-to') + 1]
  return if pv.slot_num_invalid?([slot_val, to_val], reason: '-slot & -to parameter should be 1, 2, or 3')
  return if pv.file_doesnt_exist_for_slots?([slot_val, to_val])
  return if pv.value_nil?(game_val)
  return if pv.ids_incorrect?(game_val, 1..50)

  from_save = SaveFile.find_or_create_slot(slot_val)
  to_save = SaveFile.find_or_create_slot(to_val)

  copy_games_to_save(from_save, to_save, game_val)
end

def handle_export(params, pv)
  return if pv.missing_or_no_params?(params, 5, [%w[-slot -games], %w[-slot -bk]],
                                     reason: 'Usage: export -slot [1/2/3] -games 17,35,49 (Optional: --output my_cool_disk)')

  slot_val = params[params.index('-slot') + 1]
  return if pv.slot_num_invalid?([slot_val])
  return if pv.file_doesnt_exist_for_slots?([slot_val])

  save = SaveFile.find_or_create_slot(slot_val)

  if params.include?('-bk')
    custom_vals = params[params.index('-bk') + 1]&.split(',')&.uniq
    return if pv.value_nil?(custom_vals, reason: 'Usage: export -slot 1 -bk 51,52 --output my_bk_custom_pack.ufodisk')
    return if pv.ids_incorrect?(custom_vals, 51..58, reason: '-bk values must be between 51 and 58')

    export_bk_custom_to_disk(save, custom_vals)
  else
    game_vals = params[params.index('-games') + 1]&.split(',')&.uniq
    return if pv.value_nil?(game_vals)
    return if pv.ids_incorrect?(game_vals, 1..50)

    export_games_to_disk(save, game_vals)
  end
end

def display_import_help
  fail_with_reason(reason: 'Drag and drop a .ufodisk file onto the exe!', error: false)
  fail_with_reason(reason: 'or from command line:', error: false)
  fail_with_reason(reason: '.\\ufo-st.exe "C:\\path\\to\\file\\my_cool_disk.ufodisk"', error: false)
end

def handle_view(params, pv)
  return if pv.missing_or_no_params?(params, 3, [%w[-slot]], reason: 'Usage: view -slot [1/2/3]')

  slot_val = params[params.index('-slot') + 1]
  return if pv.slot_num_invalid?([slot_val])

  save = SaveFile.find_or_create_slot(slot_val)

  if params.include?('-bk')
    handle_view_bk(params, pv, save)
  else
    view_save_game_info(save)
  end
end

def handle_view_bk(params, pv, save)
  bk_val = params[params.index('-bk') + 1]&.split(',')&.uniq
  if bk_val.nil?
    print_custom_level_slots(save)
    return
  end
  return if pv.ids_incorrect?(bk_val, 51..58, reason: "Custom level id incorrect: #{bk_val.join(', ')}")

  view_custom_bk_maps(save, bk_val)
end

def handle_goals(params, pv)
  return if pv.missing_or_no_params?(params, 3, [%w[-games]], reason: 'Usage: goals -games [1/2/3]')

  games_val = params[params.index('-games') + 1]&.split(',')&.uniq
  return if pv.ids_incorrect?(games_val, 1..50)

  print_goals_for_games(games_val)
end

def handle_delete(params, pv)
  return if pv.missing_or_no_params?(params, 5, [%w[-slot -games]], reason: 'Usage: delete -slot [1/2/3] -games 15,13')

  slot_val = params[params.index('-slot') + 1]
  game_val = params[params.index('-games') + 1]&.split(',')&.uniq
  return if pv.slot_num_invalid?([slot_val])
  return if pv.file_doesnt_exist_for_slots?([slot_val])
  return if pv.value_nil?(game_val)
  return if pv.ids_incorrect?(game_val, 1..50)

  to_save = SaveFile.find_or_create_slot(slot_val)
  delete_game_data_for_slot(game_val, to_save)
end

def export_games_to_disk(save, game_list, bk_data: nil)
  save_tool_disk_path = "#{save.filepath(folder: true)}SaveEditorDiskExports\\"
  Dir.mkdir(save_tool_disk_path) unless File.exist?(save_tool_disk_path)

  unless bk_data
    found_games = games_in_common(save, game_list)
    data_to_export = save.search_for(game_list)

    if found_games.empty?
      fail_with_reason(reason: "No game data found in slot #{save.slot} for game ids: \n!! ##{game_list.join(', #')}")
      return
    end

    data_to_export = data_to_export.values.reduce({}, :merge)
  end

  begin
    data_to_export = bk_data || JSON.generate(data_to_export)
    disk_data = SaveFile.encode_data(data_to_export) unless bk_data
    filename = save.disk_export_filename(game_list, bk_data: bk_data)

    File.open("#{save_tool_disk_path}#{filename}", 'w:UTF-8') do |file|
      data = -> { bk_data.nil? ? disk_data : bk_data }
      file.write(data.call.force_encoding('UTF-8'))
    end

    puts '!! Exported successfully, to:'
    puts "!! #{save_tool_disk_path}#{filename}"
    puts '!! Open folder? (y/N)'

    input = get_user_input
    return unless %w[y yes].include?(input)

    system('explorer', "/select,#{save_tool_disk_path}#{filename}")
  rescue StandardError => e
    puts "XX Export failed: #{e}"
  end
end

def ufodisk_type(path_to_disk)
  def check_bk(path_to_disk)
    file_data = File.read(path_to_disk).delete("\n")
    result = JSON.parse(file_data).select { |k| k == 'BK_Custom1' }
    'BK' unless result.empty?
  end

  def check_ge(path_to_disk)
    file_data = SaveFile.decode_file(path_to_disk)
    JSON.parse(file_data)
    'GE'
  end

  begin
    check_bk(path_to_disk)
  rescue StandardError
    begin
      check_ge(path_to_disk)
    rescue StandardError => e
      puts "XX Import failed: #{e}"
      puts 'XX (Press enter to exit)'
      get_user_input
      exit
    end
  end
end

def import_ufodisk(path_to_disk)
  pv = ValidateParameters.new
  case ufodisk_type(path_to_disk)
  when 'BK'
    puts 'Type: Block Koala Custom Level'
    puts

    file_data = File.read(path_to_disk).delete("\n")
    parsed = JSON.parse(file_data)

    puts ".. #{parsed.length} custom levels found!"
    puts '.. Press Enter to validate levels,'
    puts '.. or type --no-validate to skip non-crucial validations'

    input = get_user_input.split(' ')
    set_optional_params(input) if input.include?('--no-validate')

    bk = BlockKoala.new(level_codes: parsed.map { |k, v| [k, v] })

    unless bk.levels.all?(&:valid?)
      puts '(Press Enter to exit)'
      get_user_input
      exit
    end

    puts '.. Please input a slot number,'
    puts ".. and #{parsed.length} custom level ids (51->58) to import them to."
    puts ".. Example: -slot 1 -bk #{(51..(50 + parsed.length)).map(&:itself).join(',')}"
    valid_input = false
    until valid_input
      params = get_user_input.split(' ')

      exit if %w[exit quit].include?(params.first)

      next if pv.missing_or_no_params?(params, 4, [%w[-slot -bk]], reason: 'Usage: -slot 3 -bk 51,52', exact: true)

      slot_val = params[params.index('-slot') + 1]
      custom_vals = params[params.index('-bk') + 1]&.split(',')&.uniq

      next if pv.slot_num_invalid?([slot_val])
      next if pv.value_nil?(custom_vals)
      next if pv.wrong_number_of_ids?(custom_vals, parsed.length, reason: "Please enter #{parsed.length} ids")
      next if pv.ids_incorrect?(custom_vals, 51..58)

      valid_input = true
    end

    save = SaveFile.find_or_create_slot(slot_val)
    copy_custom_levels_to_save(save, custom_vals, disk_drop: parsed)
  when 'GE'
    puts 'Type: Game Export'
    puts

    disk_save = SaveFile.create_from_disk(path_to_disk)
    view_save_game_info(disk_save)

    puts '.. Copy which games? Usage: -slot [1/2/3] -games 24,39,48'
    valid_input = false
    until valid_input
      params = get_user_input.split(' ')

      exit if %w[exit quit].include?(params.first)

      next if pv.missing_or_no_params?(params, 4, [%w[-slot -games]], reason: 'Usage: -slot 3 -games 1,13,27',
                                                                      exact: true)

      slot_val = params[params.index('-slot') + 1]
      game_val = params[params.index('-games') + 1]&.split(',')&.uniq

      next if pv.slot_num_invalid?([slot_val])
      next if pv.value_nil?(game_val)
      next if pv.ids_incorrect?(game_val, 1..50)

      valid_input = true
    end

    to_save = SaveFile.find_or_create_slot(slot_val)
    copy_games_to_save(disk_save, to_save, game_val)
  else
    fail_with_reason(reason: 'UFODISK type unknown! (Press enter to exit)')
    get_user_input
    exit
  end
end

def save_data_to_slot(new_save_data, save)
  save_tool_backup_path = "#{save.filepath(folder: true)}SaveEditorBackups\\"

  unless OPTIONAL_PARAMS[:no_backup] == false
    Dir.mkdir(save_tool_backup_path) unless File.exist?(save_tool_backup_path)
    FileUtils.cp(save.filepath,
                 "#{save_tool_backup_path}\\save#{save.slot}_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.ufo")
  end

  save_path = if OPTIONAL_PARAMS[:output].nil?
                save.filepath
              else
                "#{save.filepath(folder: true)}#{OPTIONAL_PARAMS[:output]}"
              end

  File.open(save_path, 'w:UTF-8') do |file|
    file.write(new_save_data.force_encoding('UTF-8'))
  end

  puts '!! Games copied successfully, to:'
  puts "!! #{save_path}"
  puts '?? Open folder? (y/N)'
  input = get_user_input

  return unless %w[y yes].include?(input)

  system('explorer', "/select,#{save.filepath}")
end

def copy_data_to_slot(data_to_copy, data_to_delete, to_save)
  destination_data = JSON.parse(to_save.raw_save_data)

  data_to_delete.each_key do |key|
    destination_data.delete(key)
  end

  destination_data = destination_data.merge(data_to_copy)
  destination_data = JSON.generate(destination_data)

  to_save.reindex(destination_data)

  new_save_data = SaveFile.encode_data(destination_data)

  save_data_to_slot(new_save_data, to_save)
rescue StandardError => e
  puts "XX Copy failed! => #{e}"
end

def user_confirms_overwrite?(id_list, dest_slot_num, bk: false)
  puts "!! WARNING: THIS WILL REPLACE YOUR SAVE IN SLOT #{dest_slot_num} FOR:"
  puts "!! #{id_list.map { |num| GAME_INDEX[num.to_s.to_sym][:title] }.join(', ')}" unless bk
  puts "!! #{id_list.join(', ')}" if bk
  puts '!! PROCEED? (y/N)'

  input = get_user_input
  return true if %w[y yes].include?(input)

  puts '!! Copy cancelled!'
  false
end

def games_in_common(save, game_list)
  keys = save.indexed_save_data.keys
  game_list.map(&:to_i).select do |id|
    keys.include?(id)
  end
end

def copy_games_to_save(from_save, to_save, game_list)
  from_save.force_indexing
  to_save.force_indexing

  source_found_games = games_in_common(from_save, game_list)
  destination_found_games = games_in_common(to_save, game_list)

  data_to_copy = from_save.search_for(game_list)
  data_to_delete = to_save.search_for(game_list)

  if source_found_games.empty?
    if from_save.disk_path.nil?
      fail_with_reason(reason: "No game data found in slot #{from_save.slot} for game ids: \n!! ##{game_list.join(', #')}")
    else
      fail_with_reason(reason: "No game data found in ufodisk for game ids: \n!! ##{game_list.join(', #')} (Press enter to exit)")
      get_user_input
    end

    return
  end

  puts '═══════════════════════════════════════'
  puts "!!  #{from_save.disk_path.nil? ? "[SLOT #{from_save.slot}]" : '.UFODISK'}      ==>      [SLOT #{to_save.slot}]  !!"
  puts '═══════════════════════════════════════'

  unless OPTIONAL_PARAMS[:no_verify] == true
    display_game_info_for_copy(data_to_copy, data_to_delete,
                               source_found_games)
  end

  data_to_copy = data_to_copy.values.reduce({}, :merge)
  data_to_delete = data_to_delete.values.reduce({}, :merge)

  if OPTIONAL_PARAMS[:overwrite] == true || destination_found_games.empty?
    copy_data_to_slot(data_to_copy, data_to_delete, to_save)
  elsif user_confirms_overwrite?(source_found_games & destination_found_games, to_save.slot)
    copy_data_to_slot(data_to_copy, data_to_delete, to_save)
  end
end

def delete_game_data_for_slot(game_list, save)
  found_games = games_in_common(save, game_list)
  data_to_delete = save.search_for(game_list)

  if found_games.empty?
    fail_with_reason(reason: "No game data found in slot #{save.slot} for game ids: \n!! ##{game_list.join(', #')}")
    return
  end

  return unless OPTIONAL_PARAMS[:overwrite] == true || user_confirms_overwrite?(found_games, save.slot)

  data_to_delete = data_to_delete.values.reduce({}, :merge)

  begin
    source_data = JSON.parse(save.raw_save_data)

    data_to_delete.each_key do |key|
      source_data.delete(key)
    end

    source_data = JSON.generate(source_data)
    save.reindex(source_data)
    new_save_data = SaveFile.encode_data(source_data)

    save_data_to_slot(new_save_data, save)
  rescue StandardError => e
    puts "XX Delete failed! => #{e}"
  end
end

def calculate_time(time_in_ms)
  return 'EMPTY' if time_in_ms.nil?

  begin
    seconds = (time_in_ms / 1000) % 60
    minutes = (time_in_ms / (1000 * 60)) % 60
    hours = time_in_ms / (1000 * 60 * 60)

    "#{hours.to_i.to_s.rjust(2, '0')}h:#{minutes.to_i.to_s.rjust(2, '0')}m:#{seconds.to_i.to_s.rjust(2, '0')}s"
  rescue StandardError
    '???'
  end
end

def get_completion_stats(game_data, id)
  game_data = game_data[0] || {}
  {
    playTime: calculate_time(game_data["game0_gameTimeSum#{id}"]) || nil,
    hasGold: game_data["game0_goldTime#{id}"].nil?.!,
    hasCherry: game_data["game0_cherryTime#{id}"].nil?.!,
    hasGift: game_data["game0_gardenTime#{id}"].nil?.!
  }
end

def display_title(title, limit)
  if title.length > limit
    "#{title[0...limit - 3]}...".to_s
  else
    title.ljust(limit, ' ').to_s
  end
end

def view_save_game_info(save)
  save.force_indexing

  puts "╔══╣ #{!save.disk_path.nil? ? 'UFODSK' : "SLOT #{save.slot}"} ╠═════════════════════════════════╗"
  puts '║ NUM - TITLE             - PLAYTIME    - ⌂GC ║'

  (1..50).to_a.each do |game_num|
    game = GAME_INDEX[game_num.to_s.to_sym]
    internal_id = game[:id]
    search = save.indexed_save_data
    stats = get_completion_stats(search, internal_id)
    print_game_line(game, game_num, stats)
  end
  puts '╚═════════════════════════════════════════════╝'
end

def print_game_line(game, game_num, stats)
  return if stats[:playTime] == 'EMPTY'

  puts "║ ##{game_num.to_s.rjust(2,
                                 '0')} - #{display_title(game[:title],
                                                         17)} - #{stats[:playTime] == 'EMPTY' ? '-- EMPTY --' : stats[:playTime]} - #{stats[:hasGift] ? 'X' : '-'}#{stats[:hasGold] ? 'X' : '-'}#{stats[:hasCherry] ? 'X' : '-'} ║"
end

def display_game_info_for_copy(source_game_data, dest_game_data, game_list)
  return if game_list.nil? || source_game_data.nil?

  game_list.each do |game_num|
    game_num = game_num.to_s.to_sym
    game = GAME_INDEX[game_num]
    internal_id = game[:id]
    src = get_completion_stats(source_game_data, internal_id)
    dst = get_completion_stats(dest_game_data, internal_id)

    puts "╔═╣ #{game[:filename]} ╠═╗       ╔═╣ #{game[:filename]} ╠═╗"
    title = display_title(game[:title], 12)
    puts "║ #{title} ║       ║ #{title} ║"
    puts "║ #{src[:playTime].to_s.ljust(11)}  ║       ║ #{dst[:playTime].to_s.ljust(11)}  ║"
    puts "║ [#{src[:hasGold] ? 'x' : ' '}] GOLD     ║  ==>  ║ [#{dst[:hasGold] ? 'x' : ' '}] GOLD     ║"
    puts "║ [#{src[:hasCherry] ? 'x' : ' '}] CHERRY   ║       ║ [#{dst[:hasCherry] ? 'x' : ' '}] CHERRY   ║"
    puts "║ [#{src[:hasGift] ? 'x' : ' '}] GIFT     ║       ║ [#{dst[:hasGift] ? 'x' : ' '}] GIFT     ║"
    puts '╚══════════════╝       ╚══════════════╝'
  end

  true
end

def check_for_diskdrop
  puts_logo
  if !ARGV.empty? && File.exist?(ARGV[0]) && ARGV[0].end_with?('.ufodisk')
    puts_disk_detected
    import_ufodisk(ARGV[0])
  else
    fail_with_reason(reason: 'Invalid import file! try *.ufodisk. (Press any key to exit)')
    get_user_input
    exit
  end
end

def main(logo: true)
  get_help(logo: logo)

  while ARGV.count.zero?
    user_input = get_user_input
    validate_parameters(user_input)
  end
end

$stdout.sync = true

if ARGV.count != 0
  check_for_diskdrop
  exit
end

main
