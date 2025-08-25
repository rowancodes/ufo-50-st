class BlockKoala
  attr_reader :levels

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

      puts ".. #{@id}: Valid! #{OPTIONAL_PARAMS[:validate_bk] ? '' : '(Skipped necessary blocks check)'}"
      true
    end

    def block_at(row, col)
      @code[(16 * row) + col]
    end

    def invalid_length?
      return false if @code.length == 192

      fail_with_reason(reason: "#{@id}: Custom level code is not 192 characters")
      true
    end

    def illegal_characters?
      diff = @code.chars.uniq - VALID_CHARS
      return false if diff.empty?

      fail_with_reason(reason: "#{@id}: Illegal character in level code: #{diff.join(', ')}")
      true
    end

    def missing_necessary_blocks?
      return false unless OPTIONAL_PARAMS[:validate_bk]

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
      bush_not_ok? || fountain_not_ok? || black_two_not_ok? || black_three_not_ok?
    end

    def indices_that_match(character)
      sz = character.size
      (0..@code.size - sz).select { |i| @code[i, sz] == character }
    end

    def bush_not_ok?
      indices_that_match('B').any? do |index|
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
      indices_that_match('C').any? do |index|
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
      indices_that_match('7').any? do |index|
        col = index % 16
        row = index / 16
        col == 15 || row == 11
      end.tap do |bad|
        fail_with_reason(reason: "#{@id}: Black 2 blocks (7) cannot be in last column or row") if bad
      end
    end

    def black_three_not_ok?
      indices_that_match('8').any? do |index|
        col = index % 16
        row = index / 16
        col > 13 || row > 9
      end.tap do |bad|
        fail_with_reason(reason: "#{@id}: Black 3 blocks (8) cannot be in the last two columns or rows") if bad
      end
    end
  end

  def initialize(level_codes:)
    @levels = level_codes.map { |disk_id, level_code| Level.new(disk_id: disk_id, level_code: level_code) }
  end
end

def print_custom_level_slots(save)
  valid = (51..58).map { |n| "game18_customLevel#{n}" }
  ids = []
  custom_levels = JSON.parse(save.raw_save_data).each_key do |key|
    ids << key[-2..] if valid.include?(key)
  end
  return if custom_levels.empty?

  puts
  puts "Type 'view -slot [1/2/3] -bk [51/52/etc]' to see level code"
  puts
  puts "╔═╣ SLOT #{save.slot} ╠════════════════╗"
  puts '║   #51   #52   #53   #54   ║'
  puts "║   [#{ids.include?('51') ? 'X' : ' '}]   [#{ids.include?('52') ? 'X' : ' '}]   [#{ids.include?('53') ? 'X' : ' '}]   [#{ids.include?('54') ? 'X' : ' '}]   ║"
  puts "║   [#{ids.include?('55') ? 'X' : ' '}]   [#{ids.include?('56') ? 'X' : ' '}]   [#{ids.include?('57') ? 'X' : ' '}]   [#{ids.include?('58') ? 'X' : ' '}]   ║"
  puts '║   #55   #56   #57   #58   ║'
  puts '╚═══════════════════════════╝'
end

def print_custom_bk_map(level_code, slot_val, custom_id)
  puts "╔═╣ #{slot_val}:#{custom_id} ╠══════════════════════╗"
  grid = Array.new(12) { Array.new(16) }
  12.times { |y| 16.times { |x| grid[y][x] = level_code[y * 16 + x] } }
  rendered = Array.new(12) { Array.new(16) }

  def colorize(text, code)
    "\e[#{code}m#{text}\e[0m"
  end

  colors = {
    lite_red_fg: '91',
    lite_green_fg: '92',
    lite_yellow_fg: '93',
    yellow_fg_white_bg: '33;47',
    blue_fg: '94',
    red_bg: '97;41',
    lite_grey_bg: '7',
    blue_bg: '97;44',
    green_fg: '32'
  }

  symbols = {
    # guys
    'P' => colorize('P', colors[:lite_red_fg]),
    'O' => colorize('O', colors[:lite_green_fg]),

    'A' => colorize('♣', colors[:green_fg]), # small bush
    'L' => '▓', # stone path

    # arrows
    'H' => colorize('▲', colors[:yellow_fg_white_bg]),
    'I' => colorize('▼', colors[:yellow_fg_white_bg]),
    'J' => colorize('<', colors[:yellow_fg_white_bg]),
    'K' => colorize('>', colors[:yellow_fg_white_bg]),

    # star blocks
    'R' => colorize('*', colors[:lite_yellow_fg]),
    'Q' => colorize('Q', colors[:lite_yellow_fg]),

    # red blocks
    '1' => colorize('•', colors[:red_bg]),
    '2' => colorize('2', colors[:red_bg]),
    '3' => colorize('3', colors[:red_bg]),
    '4' => colorize('4', colors[:red_bg]),

    # black blocks
    '5' => colorize('5', colors[:lite_grey_bg]),
    '6' => '•',
    '7' => '2',
    '8' => '3',
    '9' => '4',

    # blue blocks
    'D' => colorize('•', colors[:blue_bg]),
    'E' => colorize('2', colors[:blue_bg]),
    'F' => colorize('3', colors[:blue_bg]),
    'G' => colorize('4', colors[:blue_bg])
  }

  12.times do |y|
    16.times do |x|
      c = grid[y][x]
      case c
      when 'B'
        rendered[y][x, 2] = [colorize('╔', colors[:green_fg]), colorize('╗', colors[:green_fg])]
        rendered[y + 1][x, 2] = ['╚', '╝']
      when 'C'
        rendered[y][x, 3] = ['╔', '═', '╗']
        rendered[y + 1][x, 3] = ['║', colorize('≈', colors[:blue_fg]), '║']
        rendered[y + 2][x, 3] = ['╚', '═', '╝']
      else
        rendered[y][x] ||= symbols[c] || c
      end
    end
  end

  rendered.each { |row| puts '║' + row.map { |c| c == '0' ? '░' : c }.join(' ') + '║' }
  puts '╚═══════════════════════════════╝'
end

def view_custom_bk_maps(save, custom_ids, level_code: nil)
  return print_custom_bk_map(level_code, 'X', 'XX') if level_code

  custom_ids.each do |id|
    game_data = save.raw_save_data
    level_code = JSON.parse(game_data).select { |k| k == "game18_customLevel#{id}" }
    if level_code.empty?
      fail_with_reason(reason: "No custom level found for Slot #{save.slot}, id: #{id}")
      return
    end
    print_custom_bk_map(level_code["game18_customLevel#{id}"], save.slot, id)
  end
end

def export_bk_custom_to_disk(save, custom_vals)
  def format_custom_level_string(code)
    formatted = code.dup
    i = 0
    (0..192).step(16) do |n|
      formatted.insert(n + i, "\n")
      i += 1
    end
    formatted
  end

  game_data = save.raw_save_data
  data_to_export = {}

  custom_vals.each do |id|
    level_code = JSON.parse(game_data).select { |k| k == "game18_customLevel#{id}" }
    if level_code.empty?
      fail_with_reason(reason: "No custom level found for Slot #{save.slot}, id: #{id}")
      return
    end
    data_to_export.merge!(level_code)
  end

  if data_to_export.empty?
    fail_with_reason(reason: "No block koala custom levels found in Slot #{save.slot}, ids: #{custom_vals.join(', ')}")
    return
  end

  last = data_to_export.length - 1
  data_formatted = '{'
  data_to_export.each_with_index do |(_k, v), i|
    data_formatted += "\n\"BK_Custom#{i + 1}\":\n\"#{format_custom_level_string(v)}\"#{i == last ? '' : ','}\n"
  end
  data_formatted += '}'

  export_games_to_disk(save, custom_vals, bk_data: data_formatted)
end

def copy_custom_levels_to_save(save, custom_id_list, disk_drop: nil)
  raise if disk_drop.nil?

  data_to_copy = {}
  destination_found_levels = []
  data_to_delete = {}

  custom_id_list.each_with_index do |id, index|
    key = "game18_customLevel#{id}"
    disk_drop_level = disk_drop["BK_Custom#{index + 1}"]
    data_to_copy[key.to_sym] = disk_drop_level

    search = JSON.parse(save.raw_save_data).select { |k| k == key }
    unless search.empty?
      destination_found_levels << id
      data_to_delete.merge!(search)
    end
  end

  if OPTIONAL_PARAMS[:overwrite] == true || destination_found_levels.empty?
    copy_data_to_slot(data_to_copy, data_to_delete, save)
  elsif user_confirms_overwrite?(destination_found_levels, save.slot, bk: true)
    copy_data_to_slot(data_to_copy, data_to_delete, save)
  end
end

def search_for_game_in_data(game_data, internal_id)
  JSON.parse(game_data).select do |key, _|
    key.match(/\bgame#{internal_id}[^0-9][a-z]+|game0+[a-z][^0-9]+#{internal_id}\b/)
  end
end
