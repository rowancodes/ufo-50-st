class BlockKoala
  attr_accessor :levels

  class Level
    VALID_CHARS = '0123456789ABCDEFGLHIJKMNOPQR'.chars.freeze

    def initialize(disk_id:, level_code:)
      @id = disk_id || ''
      @code = level_code
    end

    def valid?
      return false if invalid_length?
      return false if illegal_characters?
      return false if missing_necessary_blocks?
      return false if invalid_block_positions?

      puts ".. #{@id}: Valid! #{$optional_params[:validate_bk] ? '' : '(Skipped necessary blocks check)'}"
      true
    end

    def block_at(row, col)
      @code[(16 * row) + col]
    end

    def invalid_length?
      return unless @code.length != 192

      fail_with_reason(reason: "#{@id}: Custom level code is not 192 characters")
      true
    end

    def illegal_characters?
      diff = @code.chars.uniq - VALID_CHARS
      return if diff.empty?

      fail_with_reason(reason: "#{@id}: Illegal character in level code: #{diff.join(', ')}")
      true
    end

    def missing_necessary_blocks?
      return false unless $optional_params[:validate_bk]

      if !@code.include?('P')
        fail_with_reason(reason: "#{@id}: No player character (P) in custom level code")
        true
      elsif @code.count('P') != 1
        fail_with_reason(reason: "#{@id}: More than one player (P) in custom level code")
        true
      elsif !@code.include?('R')
        fail_with_reason(reason: "#{@id}: No star block (R) in custom level code")
        true
      elsif !@code.include?('Q')
        fail_with_reason(reason: "#{@id}: No star block destination (Q) in custom level code")
        true
      else
        false
      end
    end

    def invalid_block_positions?
      return true if bush_not_ok?
      return true if fountain_not_ok?
      return true if black_two_not_ok?
      return true if black_three_not_ok?

      false
    end

    def indices_of_matches(target)
      sz = target.size
      (0..@code.size - sz).select { |i| @code[i, sz] == target }
    end

    def bush_not_ok?
      indices = indices_of_matches('B')
      indices.any? do |index|
        col = index % 16
        row = index / 16
        @code[index + 1] != '0' ||
          @code[((row + 1) * 16) + col] != '0' ||
          @code[((row + 1) * 16) + (col + 1)] != '0'
      end.tap do |bad|
        fail_with_reason(reason: "#{@id}: One or more bush (B) does not have 2x2 of space") if bad
      end
    end

    def fountain_not_ok?
      indices = indices_of_matches('C')
      indices.any? do |index|
        col = index % 16
        row = index / 16
        @code[index + 1] != '0' ||
          @code[index + 2] != '0' ||
          @code[((row + 1) * 16) + col] != '0' ||
          @code[((row + 1) * 16) + (col + 1)] != '0' ||
          @code[((row + 1) * 16) + (col + 2)] != '0' ||
          @code[((row + 2) * 16) + col] != '0' ||
          @code[((row + 2) * 16) + (col + 1)] != '0' ||
          @code[((row + 2) * 16) + (col + 2)] != '0'
      end.tap do |bad|
        fail_with_reason(reason: "#{@id}: One or more fountains (C) do not have 3x3 of space") if bad
      end
    end

    def black_two_not_ok?
      indices = indices_of_matches('7')
      indices.any? do |index|
        col = index % 16
        row = index / 16
        col == 15 || row == 11
      end.tap do |bad|
        fail_with_reason(reason: "#{@id}: Black 2 blocks (7) cannot be in last column or row") if bad
      end
    end

    def black_three_not_ok?
      indices = indices_of_matches('8')
      indices.any? do |index|
        col = index % 16
        row = index / 16
        col > 13 || row > 9
      end.tap do |bad|
        fail_with_reason(reason: "#{@id}: Black 3 blocks (8) cannot be in the last two columns or rows") if bad
      end
    end
  end

  def initialize(level_codes:)
    @levels = level_codes.map { |set| Level.new(disk_id: set[0], level_code: set[1]) }
  end
end

def print_custom_level_slots(slot_val)
  valid = (51..58).map { |n| "game18_customLevel#{n}" }
  game_data = decode_file(filepath_for_slot(slot_val))
  ids = []
  custom_levels = JSON.parse(game_data).each_key do |key|
    if valid.include?(key)
      ids.push(key[-2..])
      true
    else
      false
    end
  end

  return if custom_levels.empty?

  puts
  puts "Type 'view -slot [1/2/3] -bk [51/52/etc]' to see level code"
  puts "SLOT #{slot_val}:\t║ #51 ║ #52 ║ #53 ║ #54 ║"
  puts "\t║ [#{ids.include?('51') ? 'X' : ' '}] ║ [#{ids.include?('52') ? 'X' : ' '}] ║ [#{ids.include?('53') ? 'X' : ' '}] ║ [#{ids.include?('54') ? 'X' : ' '}] ║"
  puts "\t║ [#{ids.include?('55') ? 'X' : ' '}] ║ [#{ids.include?('56') ? 'X' : ' '}] ║ [#{ids.include?('57') ? 'X' : ' '}] ║ [#{ids.include?('58') ? 'X' : ' '}] ║"
  puts "\t║ #55 ║ #56 ║ #57 ║ #58 ║"
end

def print_custom_bk_map(level_code, slot_val, custom_id)
  puts "╔════╣ #{slot_val}:#{custom_id} ╠════╗"
  12.times do |y|
    puts "║#{level_code[(y * 16)...((y * 16) + 16)].gsub('0', '.')}║"
  end
  puts '╚════════════════╝'
end

def view_custom_bk_maps(slot_val, custom_ids, level_code: nil)
  return print_custom_bk_map(level_code, 'X', 'XX') unless level_code.nil?

  level_codes = []

  custom_ids.each do |id|
    game_data = decode_file(filepath_for_slot(slot_val))
    search_for_game_in_data(game_data, GAME_INDEX[:"15"][:id])
    level_code = JSON.parse(game_data).select { |k| k == "game18_customLevel#{id}" }

    if level_code.empty?
      fail_with_reason(reason: "No custom level found for Slot #{slot_val}, id: #{id}")
      return
    end

    level_codes.push([level_code["game18_customLevel#{id}"], id])
  end

  level_codes.each { |set| print_custom_bk_map(set[0], slot_val, set[1]) }
end

def export_bk_custom_to_disk(slot_val, custom_vals)
  def format_custom_level_string(code)
    formatted = code
    i = 0
    (0..192).step(16) do |n|
      formatted.insert(n + i, "\n")
      i += 1
    end
    formatted
  end

  game_data = decode_file(filepath_for_slot(slot_val))
  game_data = search_for_game_in_data(game_data, GAME_INDEX[:"15"][:id])

  data_to_export = {}

  custom_vals.each do |id|
    level_code = game_data.select { |k| k == "game18_customLevel#{id}" }

    if level_code.empty?
      fail_with_reason(reason: "No custom level found for Slot #{slot_val}, id: #{id}")
      return
    end

    data_to_export.merge!(level_code)
  end

  if data_to_export.empty?
    fail_with_reason(reason: "No block koala custom levels found in Slot #{slot_val}, ids: #{custom_vals.join(', ')}")
    return
  end

  last = data_to_export.length - 1
  data_formatted = '{'
  data_to_export.each_with_index do |(_k, v), i|
    data_formatted += "\n\"BK_Custom#{i + 1}\":\n\"#{format_custom_level_string(v)}\"#{i == last ? '' : ','}\n"
  end
  data_formatted += '}'

  export_games_to_disk(slot_val, custom_vals, disk_type: 'BK', bk_data: data_formatted)
end

def copy_custom_levels_to_save(_source_num, destination_num, custom_id_list, disk_drop: nil)
  disk_drop.nil? ? raise : disk_drop

  destination_data = decode_file(filepath_for_slot(destination_num))

  data_to_copy = {}
  destination_found_levels = []
  data_to_delete = {}

  custom_id_list.each_with_index do |id, index|
    key = "game18_customLevel#{id}"
    disk_drop_level = disk_drop["BK_Custom#{index + 1}"]
    level_data = {}
    level_data[key.to_sym] = disk_drop_level

    data_to_copy.merge!(level_data)

    search = JSON.parse(destination_data).select { |k| k == key }

    unless search.empty?
      destination_found_levels.push(id)
      data_to_delete.merge!(search)
    end
  end

  if OPTIONAL_PARAMS[:overwrite] == true || destination_found_levels.empty?
    copy_data_to_slot(data_to_copy, data_to_delete, destination_data, destination_num)
  elsif user_confirms_overwrite?(
    destination_found_levels, destination_num, bk: true
  )
    copy_data_to_slot(data_to_copy, data_to_delete, destination_data, destination_num)
  end
end