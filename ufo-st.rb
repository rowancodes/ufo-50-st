# UFO 50 Save Tool (or LX-III Save Tool)
# made by rowancodes
# ---------------------
# UFO 50 is a video game by Mossmouth, LLC @ https://50games.fun/

require "base64"
require "json"
require "fileutils"
require "date"

$optional_params = {output: nil, no_verify: false, overwrite: false, verbose: false, validate_bk: true}

class BlockKoala
    attr_accessor :levels

    class Level
        def initialize(disk_id:, level_code:)
            @id = disk_id || ""
            @code = level_code
        end

        def valid?
            return false if validate_length
            return false if validate_illegal_characters
            return false if validate_necessary_blocks
            return false if validate_block_positions 
            puts ".. #{@id}: Valid! #{$optional_params[:validate_bk] ? "" : "(Skipped necessary blocks check)"}"
            true
        end

        def block_at(row, col)
            # row: 0 -> 12
            # col: 0 -> 15
            code.split("")[(16*row)+col] 
        end

        def validate_length
            if @code.length != 192
                fail_with_reason(reason: "#{@id}: Custom level code is not 192 characters")
                return true
            end
        end

        def validate_illegal_characters
            valid = "0123456789ABCDEFGLHIJKMNOPQR".split("")
            diff = @code.split("").uniq - valid
            if diff.empty?.!
                fail_with_reason(reason: "#{@id}: Illegal character in level code: #{diff.join(", ")}") 
                return true
            end
        end

        def validate_necessary_blocks
            return false if $optional_params[:validate_bk].!

            if @code.include?("P").!
                fail_with_reason(reason: "#{@id}: No player character (P) in custom level code")
                return true 
            elsif @code.count("P") != 1 
                fail_with_reason(reason: "#{@id}: More than one player (P) in custom level code") 
                return true
            elsif @code.include?("R").!
                fail_with_reason(reason: "#{@id}: No star block (R) in custom level code")
                return true
            elsif @code.include?("Q").!
                fail_with_reason(reason: "#{@id}: No star block destination (Q) in custom level code") 
                return true
            end
            false
        end

        def validate_block_positions
            def indices_of_matches(str, target)
                sz = target.size
                (0..str.size-sz).select { |i| str[i,sz] == target }
            end

            def bush_not_ok?(indices)
                return false if indices.empty?

                indices.any? do |index|
                    col = index % 16
                    row = (index / 16).floor

                    @code[index+1] != "0" || @code[((row+1)*16)+col] != "0" || @code[((row+1)*16)+(col+1)] != "0"
                end
            end

            def fountain_not_ok?(indices)
                return false if indices.empty?
                
                indices.any? do |index|
                    col = index % 16
                    row = (index / 16).floor

                    @code[index+1] != "0" || 
                    @code[index+2] != "0" || 
                    @code[((row+1)*16)+col] != "0" || 
                    @code[((row+1)*16)+(col+1)] != "0" ||
                    @code[((row+1)*16)+(col+2)] != "0" ||
                    @code[((row+2)*16)+col] != "0" || 
                    @code[((row+2)*16)+(col+1)] != "0" ||
                    @code[((row+2)*16)+(col+2)] != "0" 
                end
            end

            def black_two_not_ok?(indices)
                return false if indices.empty?
                
                indices.any? do |index|
                    col = index % 16
                    row = (index / 16).floor

                    col == 15 || row == 11
                end
            end

            def black_three_not_ok?(indices)
                return false if indices.empty?
                
                indices.any? do |index|
                    col = index % 16
                    row = (index / 16).floor

                    col > 13 || row > 9
                end
            end
            
            if bush_not_ok?(indices_of_matches(@code, "B"))
                fail_with_reason(reason: "#{@id}: One or more bush (B) does not have 2x2 of space") 
                return true
            elsif fountain_not_ok?(indices_of_matches(@code, "C"))
                fail_with_reason(reason: "#{@id}: One or more fountains (C) do not have 3x3 of space")
                return true
            elsif black_two_not_ok?(indices_of_matches(@code, "7"))
                fail_with_reason(reason: "#{@id}: Black 2 blocks (7) cannot be in last column or row")
                return true
            elsif black_three_not_ok?(indices_of_matches(@code, "8"))
                fail_with_reason(reason: "#{@id}: Black 3 blocks (8) cannot be in the last two columns or rows")
                return true
            end
            false  
        end
    end

    def initialize(level_codes:, parsed_data:)
        @levels = level_codes.map { |set| Level.new(disk_id: set[0], level_code: set[1]) }
    end
end

class ValidateParameters
    def missing_or_no_params?(params, expected_count, expected_params, reason: "Incorrect usage.", exact: false)
        if (params.count < expected_count) || ((params.count != expected_count) && exact) || expected_params.any? { |set| set.all? { |param| params.include?(param) }}.!
            fail_with_reason(reason: reason, error: false)
            return true
        end
        false
    end

    def slot_num_invalid?(slots, reason: "Slot parameter should be 1, 2, or 3.")
        if slots.all? { |val| %w(1 2 3).include?(val) }.!
            fail_with_reason(reason: reason) 
            return true
        end
        false
    end

    def file_doesnt_exist_for_slots?(slots, reason: "Save file doesn't exist.")
        slots.each do |filenum|
            filepath = filepath_for_slot(filenum)
            if File.exists?(filepath).!
                fail_with_reason(reason: reason)
                return true
            end
        end
        false
    end

    def value_nil?(game_val, reason: "No game ids listed. Example: (1,13,27)")
        if game_val.nil?
            fail_with_reason(reason: reason)
            return true
        end
        false
    end

    def ids_incorrect?(list, range, reason: "One or more game ids incorrect: ")
        def vals_in_range?(vals, range)
            vals.all? do |num|
                range.to_a.include?(num.to_i)
            end
        end

        if !vals_in_range?(list, range)
            fail_with_reason(reason: "#{reason}#{list.join(", ")}")
            return true
        end
        false
    end

    def wrong_number_of_ids?(list, expected_count, reason: "Incorret number of ids")
        if list.length != expected_count
            fail_with_reason(reason: reason)
            return true
        end
        false
    end
end

def game_index 
    {
        :"1"=>{
            :title=>"BARBUTA",
            :filename=>"TRAP.ufo",
            :id=>"40"
        },
        :"2"=>{
            :title=>"BUG HUNTER",
            :filename=>"BUGS.ufo",
            :id=>"20"
        },
        :"3"=>{
            :title=>"NINPEK",
            :filename=>"NINJ.ufo",
            :id=>"34"
        },
        :"4"=>{
            :title=>"PAINT CHASE",
            :filename=>"PCHA.ufo",
            :id=>"49"
        },
        :"5"=>{
            :title=>"MAGIC GARDEN",
            :filename=>"CUTE.ufo",
            :id=>"27"
        },
        :"6"=>{
            :title=>"MORTOL",
            :filename=>"SAC1.ufo",
            :id=>"29"
        },
        :"7"=>{
            :title=>"VELGRESS",
            :filename=>"FRAG.ufo",
            :id=>"15"
        },
        :"8"=>{
            :title=>"PLANET ZOLDATH",
            :filename=>"ZOLD.ufo",
            :id=>"48"
        },
        :"9"=>{
            :title=>"ATTACTICS",
            :filename=>"ARMY.ufo",
            :id=>"2"
        },
        :"10"=>{
            :title=>"DEVILITION",
            :filename=>"DIAB.ufo",
            :id=>"5"
        },
        :"11"=>{
            :title=>"KICK CLUB",
            :filename=>"BALL.ufo",
            :id=>"26"
        },
        :"12"=>{
            :title=>"AVIANOS",
            :filename=>"BIRD.ufo",
            :id=>"50"
        },
        :"13"=>{
            :title=>"MOONCAT",
            :filename=>"BAR2.ufo",
            :id=>"11"
        },
        :"14"=>{
            :title=>"BUSHIDO BALL",
            :filename=>"BUSH.ufo",
            :id=>"22"
        },
        :"15"=>{
            :title=>"BLOCK KOALA",
            :filename=>"BLOK.ufo",
            :id=>"18"
        },
        :"16"=>{
            :title=>"CAMOUFLAGE",
            :filename=>"CAMO.ufo",
            :id=>"4"
        },
        :"17"=>{
            :title=>"CAMPANELLA",
            :filename=>"UFO1.ufo",
            :id=>"3"
        },
        :"18"=>{
            :title=>"GOLFARIA",
            :filename=>"GOLF.ufo",
            :id=>"6"
        },
        :"19"=>{
            :title=>"THE BIG BELL RACE",
            :filename=>"UFOP.ufo",
            :id=>"28"
        },
        :"20"=>{
            :title=>"WARPTANK",
            :filename=>"WARP.ufo",
            :id=>"16"
        },
        :"21"=>{
            :title=>"WALDORF'S JOURNEY",
            :filename=>"WALH.ufo",
            :id=>"21"
        },
        :"22"=>{
            :title=>"PORGY",
            :filename=>"SUBH.ufo",
            :id=>"10"
        },
        :"23"=>{
            :title=>"ONION DELIVERY",
            :filename=>"SHAD.ufo",
            :id=>"32"
        },
        :"24"=>{
            :title=>"CARAMEL CARAMEL",
            :filename=>"PHOT.ufo",
            :id=>"46"
        },
        :"25"=>{
            :title=>"PARTY HOUSE",
            :filename=>"PART.ufo",
            :id=>"36"
        },
        :"26"=>{
            :title=>"HOT FOOT",
            :filename=>"HOTF.ufo",
            :id=>"43"
        },
        :"27"=>{
            :title=>"DIVERS",
            :filename=>"DIVE.ufo",
            :id=>"19"
        },
        :"28"=>{
            :title=>"RAIL HEIST",
            :filename=>"TRAI.ufo",
            :id=>"13"
        },
        :"29"=>{
            :title=>"VAINGER",
            :filename=>"GRAV.ufo",
            :id=>"7"
        },
        :"30"=>{
            :title=>"ROCK ON! ISLAND",
            :filename=>"DINO.ufo",
            :id=>"44"
        },
        :"31"=>{
            :title=>"PINGOLF",
            :filename=>"PING.ufo",
            :id=>"23"
        },
        :"32"=>{
            :title=>"MORTOL 2",
            :filename=>"SAC2.ufo",
            :id=>"1"
        },
        :"33"=>{
            :title=>"FIST HELL",
            :filename=>"FIST.ufo",
            :id=>"9"
        },
        :"34"=>{
            :title=>"OVERBOLD",
            :filename=>"OVER.ufo",
            :id=>"30"
        },
        :"35"=>{
            :title=>"CAMPANELLA 2",
            :filename=>"UFO2.ufo",
            :id=>"38"
        },
        :"36"=>{
            :title=>"HYPER CONTENDER",
            :filename=>"PLAT.ufo",
            :id=>"42"
        },
        :"37"=>{
            :title=>"VALBRACE",
            :filename=>"DUNS.ufo",
            :id=>"35"
        },
        :"38"=>{
            :title=>"RAKSHASA",
            :filename=>"RAKS.ufo",
            :id=>"24"
        },
        :"39"=>{
            :title=>"STAR WISPIR",
            :filename=>"VERT.ufo",
            :id=>"17"
        },
        :"40"=>{
            :title=>"GRIMSTONE",
            :filename=>"BRIM.ufo",
            :id=>"12"
        },
        :"41"=>{
            :title=>"LORDS OF DISKONIA",
            :filename=>"DISK.ufo",
            :id=>"33"
        },
        :"42"=>{
            :title=>"NIGHT MANOR",
            :filename=>"NIGH.ufo",
            :id=>"39"
        },
        :"43"=>{
            :title=>"ELFAZAR'S HAT",
            :filename=>"ELFA.ufo",
            :id=>"31"
        },
        :"44"=>{
            :title=>"PILOT QUEST",
            :filename=>"ZOL2.ufo",
            :id=>"37"
        },
        :"45"=>{
            :title=>"MINI & MAX",
            :filename=>"INFI.ufo",
            :id=>"41"
        },
        :"46"=>{
            :title=>"COMBATANTS",
            :filename=>"ANTW.ufo",
            :id=>"25"
        },
        :"47"=>{
            :title=>"QUIBBLE RACE",
            :filename=>"QUIB.ufo",
            :id=>"14"
        },
        :"48"=>{
            :title=>"SEASIDE DRIVE",
            :filename=>"SEAS.ufo",
            :id=>"47"
        },
        :"49"=>{
            :title=>"CAMPANELLA 3",
            :filename=>"UFO3.ufo",
            :id=>"8"
        },
        :"50"=>{
            :title=>"CYBER OWLS",
            :filename=>"WNST.ufo",
            :id=>"45"
        }
    }
end

def set_optional_params(params)
    if params.include?("--output")
        arg_index = params.index("--output")+1
        $optional_params[:output] = params[arg_index]
    end

    $optional_params[:no_verify] = true if params.include?("--no-verify")
    $optional_params[:overwrite] = true if params.include?("--overwrite")
    $optional_params[:verbose] = true if params.include?("--verbose")
    $optional_params[:validate_bk] = false if params.include?("--no-validate")
end

def print_custom_level_slots(slot_val)
    valid = (51..58).map { |n| "game18_customLevel#{n}" }
    game_data = decode_file(filepath_for_slot(slot_val))
    ids = []
    custom_levels = JSON.parse(game_data).each do |key, _v| 
        if valid.include?(key) 
            ids.push(key[-2..-1]) 
            true
        else
            false
        end
    end

    return if custom_levels.empty?

    puts
    puts "Type 'view -slot [1/2/3] -bk [51/52/etc]' to see level code"
    puts "SLOT #{slot_val}:\t║ #51 ║ #52 ║ #53 ║ #54 ║"
    puts "\t║ [#{ids.include?("51") ? "X" : " "}] ║ [#{ids.include?("52") ? "X" : " "}] ║ [#{ids.include?("53") ? "X" : " "}] ║ [#{ids.include?("54") ? "X" : " "}] ║"
    puts "\t║ [#{ids.include?("55") ? "X" : " "}] ║ [#{ids.include?("56") ? "X" : " "}] ║ [#{ids.include?("57") ? "X" : " "}] ║ [#{ids.include?("58") ? "X" : " "}] ║"
    puts "\t║ #55 ║ #56 ║ #57 ║ #58 ║"
end

def print_games_to_screen
    def tab_amount(game)
        return "\t" if game[:title].length >= 12
        return "\t\t" if game[:title].length >= 5
    end

    puts "╔══════════╣ UFOSOFT LIBRARY ╠══════════╗"
    puts "║                                       ║"
    game_index.each do |num, game|
        puts "║  ##{num.to_s.rjust(2, '0')} - #{game[:filename]} - #{game[:title]}#{tab_amount(game)}║"
    end
    puts "╚═══════════════════════════════════════╝"
end

def print_custom_bk_map(level_code, slot_val, custom_id)
    puts "╔════╣ #{slot_val}:#{custom_id} ╠════╗"
    12.times do |y|
        puts "║#{level_code[(y*16)...((y*16)+16)].gsub("0", ".")}║"
    end
    puts "╚════════════════╝"
end

def view_custom_bk_maps(slot_val, custom_ids, level_code: nil)
    return print_custom_bk_map(level_code, "X", "XX") if level_code.nil?.!

    level_codes = []

    custom_ids.each do |id|
        game_data = decode_file(filepath_for_slot(slot_val))
        search_for_game_in_data(game_data, game_index[:"15"][:id])
        level_code = JSON.parse(game_data).select { |k, _v| k == "game18_customLevel#{id}" }

        if level_code.empty?
            fail_with_reason(reason: "No custom level found for Slot #{slot_val}, id: #{id}")
            return
        end

        level_codes.push([level_code["game18_customLevel#{id}"], id])
    end

    level_codes.each { |set| print_custom_bk_map(set[0], slot_val, set[1]) }
end

def puts_logo
    puts "==========================================================="
    puts ":::        :::    :::   ::::::::::: ::::::::::: :::::::::::"
    puts ":+:        :+:    :+:       :+:         :+:         :+:    "
    puts "+:+         +:+  +:+        +:+         +:+         +:+    "
    puts "+#+          +#++:+  +#+    +#+         +#+         +#+    "
    puts "+#+         +#+  +#+        +#+         +#+         +#+    "
    puts "#+#        #+#    #+#       #+#         #+#         #+#    "
    puts "########## ###    ###   ########### ########### ###########"
    puts "\t\t\tSAVE TOOL !"
    puts "==========================================================="
    puts "\t\t  PLEASE CLOSE YOUR GAME!"
end

def puts_disk_detected
    puts " _.........._ "
    puts "||          ||"
    puts "||   UFO    ||"
    puts "||   DISK   ||"
    puts "||          ||"
    puts "||__________||"
    puts "|   ______   |"
    puts "|__|____|_|__|"
    puts
    puts ".ufodisk detected!"
    puts
end

def get_help(logo: true)
    puts
    puts_logo if logo == true
    puts "Usage:"
    puts "\thelp\t=>\tdisplays this information"
    puts "\tview\t=>\tview game data for slot"
    puts "\tcopy\t=>\tcopy games from one save to another"
    puts "\texport\t=>\texports games to a .ufodisk file"
    puts "\t\t\t to share w/ your friends :3"
    puts "\timport\t=>\tdisplays import help"
    puts "\tlist\t=>\tlist ufosoft games"
    puts "\texit\t=>\tcloses the program"
    puts "Params:"
    puts "\t-slot\t=>\tsource save slot [1/2/3]"
    puts "\t-to\t=>\tdestination save slot [1/2/3]"
    puts "\t-games\t=>\tlist of games to copy/export"
    puts "\t-bk\t=>\tfor export/import/view of block"
    puts "\t\t\t koala custom levels"
    puts "Optional:"
    puts "\t--output    =>\tspecify an output filename"
    puts "\t--no-verify =>\tdoes not verify game choice"
    puts "\t\t\tbefore continuing (be careful!)"
    puts "\t--overwrite =>\toverwrites existing game data"
    puts "\t\t\twithout asking (be careful!)"
    puts "v1.1.0"
end

def decode_file(filepath)
    input = File.open(filepath, "r:utf-8")
    output = Base64.decode64(input.readline.force_encoding("UTF-8")).force_encoding("UTF-8")
end

def encode_data(game_data)
    end_char = "\u0000".force_encoding("UTF-8")

    (Base64.encode64(game_data.force_encoding("UTF-8")).delete("\n") + end_char).force_encoding("UTF-8")
end

def decode_data(game_data)
    Base64.decode64(game_data.force_encoding("UTF-8")).force_encoding("UTF-8")
end

def get_user_input
    print ">> "
    input = $stdin.gets.chomp
    input.gsub!(/[^a-zA-Z0-9\-,._ ]+[a-zA-Z]/,'')
    input.downcase
end

def fail_with_reason(reason: "FailureUnknown", error: true)
    error ? (print "!! ERROR: ") : (print "!! ")
    puts reason
    true 
end

def export_bk_custom_to_disk(slot_val, custom_vals)
    def format_custom_level_string(code)
        formatted = code
        i = 0
        (0..192).step(16) do |n|
            formatted = formatted.insert(n+i, "\n")
            i += 1
        end
        formatted
    end

    game_data = decode_file(filepath_for_slot(slot_val))
    game_data = search_for_game_in_data(game_data, game_index[:"15"][:id])

    data_to_export = {}

    custom_vals.each do |id|
        level_code = game_data.select { |k, _v| k == "game18_customLevel#{id}" }
        
        if level_code.empty?
            fail_with_reason(reason: "No custom level found for Slot #{slot_val}, id: #{id}")
            return
        end

        data_to_export.merge!(level_code)
    end

    if data_to_export.empty?
        fail_with_reason(reason: "No block koala custom levels found in Slot #{slot_val}, ids: #{custom_vals.join(", ")}")
        return
    end

    last = data_to_export.length-1
    data_formatted = "{"
    data_to_export.each_with_index do |(k, v), i|
        data_formatted += "\n\"BK_Custom#{i+1}\":\n\"#{format_custom_level_string(v)}\"#{i == last ? "" : ","}\n"
    end
    data_formatted += "}"

    export_games_to_disk(slot_val, custom_vals, disk_type: "BK", bk_data: data_formatted)
end 

def validate_parameters(params)
    pv = ValidateParameters.new
    params = params.split(" ")

    return if params.empty?

    set_optional_params(params)

    if    params.first == "help"
        get_help
    elsif params.first == "copy"
        return if pv.missing_or_no_params?(params, 7, [%w(-slot -to -games)], reason: "Usage: copy -slot [1/2/3] -to [1/2/3] -games 1,13,27")

        game_val    = params[params.index("-games")+1]&.split(",")&.uniq
        slot_val    = params[params.index("-slot")+1]
        to_val      = params[params.index("-to")+1]

        return if pv.slot_num_invalid?([slot_val, to_val], reason: "-slot & -to parameter should be 1, 2, or 3")
        return if pv.file_doesnt_exist_for_slots?([slot_val, to_val])
        return if pv.value_nil?(game_val)
        return if pv.ids_incorrect?(game_val, (1..50))

        copy_games_to_save(slot_val, to_val, game_val)
    elsif params.first == "export"
        return if pv.missing_or_no_params?(params, 5, [%w(-slot -games), %w(-slot -bk)], reason: "Usage: export -slot [1/2/3] -games 17,35,49 (Optional: --output my_cool_disk)")

        slot_val = params[params.index("-slot")+1]

        return if pv.slot_num_invalid?([slot_val])
        return if pv.file_doesnt_exist_for_slots?([slot_val])

        if params.include?("-bk")
            custom_vals = params[params.index("-bk")+1]&.split(",")&.uniq

            return if pv.value_nil?(custom_vals, reason: "Usage: export -slot 1 -bk 51,52 --output my_bk_custom_pack.ufodisk")
            return if pv.ids_incorrect?(custom_vals, (51..58), reason: "-bk values must be between 51 and 58")

            export_bk_custom_to_disk(slot_val, custom_vals)
        else
            game_vals   = params[params.index("-games")+1]&.split(",")&.uniq

            return if pv.value_nil?(game_vals)
            return if pv.ids_incorrect?(game_vals, (1..50))

            export_games_to_disk(slot_val, game_vals)
        end
    elsif params.first == "import"
        fail_with_reason(reason: "Drag and drop a .ufodisk file onto the exe!", error: false)
        fail_with_reason(reason: "or from command line:", error: false)
        fail_with_reason(reason: ".\\ufo-st.exe \"C:\\path\\to\\file\\my_cool_disk.ufodisk\"", error: false)
    elsif params.first == "list"
        print_games_to_screen
    elsif params.first == "view"
        return if pv.missing_or_no_params?(params, 3, [%w(-slot)], reason: "Usage: view -slot [1/2/3]")

        slot_val = params[params.index("-slot")+1]

        return if pv.slot_num_invalid?([slot_val])

        if params.include?("-bk")
            bk_val = params[params.index("-bk")+1]&.split(",")&.uniq

            if bk_val.nil?
                print_custom_level_slots(slot_val)
                return
            end

            return if pv.ids_incorrect?(bk_val, (51..58), reason: "Custom level id incorrect: #{bk_val.join(", ")}")

            view_custom_bk_maps(slot_val, bk_val)
        else
            view_save_game_info(slot_val)
        end
    elsif params.first == "exit" || params.first == "quit"
        puts "bye bye :3"
        exit
    else
        fail_with_reason(reason: "?? Unknown command: #{params.first}", error: false)
    end 
end

def export_games_to_disk(slot_val, games_list, disk_type: nil, bk_data: nil)
    save_tool_disk_path = "#{filepath_for_slot(nil, just_folder: true)}SaveEditorDiskExports\\"
    Dir.mkdir(save_tool_disk_path) unless File.exists?(save_tool_disk_path)

    if !bk_data
        game_data = decode_file(filepath_for_slot(slot_val))

        found_games = []
        data_to_export = {}

        games_list.each do |game_num|
            game = game_index[game_num.to_i.to_s.to_sym]
            internal_id = game[:id]

            search = filter_data(search_for_game_in_data(game_data, internal_id))

            if search.empty?.!
                found_games.push(game_num) 
                data_to_export.merge!(search)
            end
        end

        if found_games.empty?
            fail_with_reason(reason: "No game data found in slot #{slot_val} for game ids: \n!! ##{games_list.join(", #")}")
            return
        end
    end

    begin
        bk_data ? (data_to_export = JSON.generate(data_to_export)) : (data_to_export = bk_data)
        disk_data = encode_data(data_to_export) if !bk_data

        filename = nil
        if $optional_params[:output] != nil
            filename = $optional_params[:output].split(".").first + ".ufodisk"
        elsif disk_type == "BK"
            filename = "BK-SLOT#{slot_val}-#{games_list.join("-")}-#{DateTime.now.strftime("%Y-%m-%d-%H-%M-%S")}.ufodisk"
        else
            filename = "#{profile_name(game_data)}-#{games_list.join("-")}#{DateTime.now.strftime("%Y-%m-%d-%H-%M-%S")}.ufodisk"
        end

        File.open("#{save_tool_disk_path}#{filename}", "w:UTF-8") do |file|
            if bk_data
                file.write(bk_data.force_encoding("UTF-8"))
            else
                file.write(disk_data.force_encoding("UTF-8"))
            end
        end
    
        puts "!! Exported successfully, to:"
        puts "!! #{save_tool_disk_path}#{filename}"
        puts "!! Open folder? (y/N)"
        input = get_user_input
        if input == "y" || input == "yes"
            system("explorer", "/select,#{save_tool_disk_path}#{filename}")
        else
            return
        end
    rescue => e
        puts "XX Export failed: #{e}"
        raise
    end
end

def profile_name(game_data)
    name = JSON.parse(game_data).select { |key, _v| key.include?("game0_profileName") }
    name.nil? ? "EXPORT" : "#{name["game0_profileName"]}"
end

def ufodisk_type(path_to_disk)
    def check_bk(path_to_disk)
        file_data = File.read(path_to_disk).delete("\n")
        result = JSON.parse(file_data).select { |k,_v| k == "BK_Custom1" }
        return "BK" if result.empty?.!
    end

    def check_ge(path_to_disk)
        file_data = decode_file(path_to_disk)
        JSON.parse(file_data)
        return "GE"
    end

    begin
        check_bk(path_to_disk)
    rescue
        begin
            check_ge(path_to_disk)
        rescue => e
            puts "XX Import failed: #{e}"
            puts "XX (Press enter to exit)"
            get_user_input
            exit
        end
    end
end

def import_ufodisk(path_to_disk)
    pv = ValidateParameters.new
    case ufodisk_type(path_to_disk)
    when "BK"
        puts "Type: Block Koala Custom Level"
        puts

        file_data = File.read(path_to_disk).delete("\n")
        parsed = JSON.parse(file_data)

        puts ".. #{parsed.length} custom levels found!"
        puts ".. Press Enter to validate levels,"
        puts ".. or type --no-validate to skip non-crucial validations"

        input = get_user_input.split(" ")
        set_optional_params(input) if input.include?("--no-validate")

        bk = BlockKoala.new(level_codes: parsed.map {|k, v| [k,v]}, parsed_data: parsed)

        if bk.levels.all?(&:valid?).!
            puts "(Press Enter to exit)"
            get_user_input
            exit
        end

        puts ".. Please input a slot number,"
        puts ".. and #{parsed.length} custom level ids (51->58) to import them to."
        puts ".. Example: -slot 1 -bk #{(51..(50+parsed.length)).map(&:itself).join(",")}"
        valid_input = false
        until valid_input
            params = get_user_input.split(" ")

            exit if params.first == "exit" || params.first == "quit"

            next if pv.missing_or_no_params?(params, 4, [%w(-slot -bk)], reason: "Usage: -slot 3 -bk 51,52", exact: true)

            slot_val = params[params.index("-slot")+1]
            custom_vals = params[params.index("-bk")+1]&.split(",")&.uniq

            next if pv.slot_num_invalid?([slot_val])
            next if pv.value_nil?(custom_vals)
            next if pv.wrong_number_of_ids?(custom_vals, parsed.length, reason: "Please enter #{parsed.length} ids")
            next if pv.ids_incorrect?(custom_vals, (51..58))

            valid_input = true
        end

        copy_custom_levels_to_save(nil, slot_val, custom_vals, disk_drop: parsed)
    when "GE"
        puts "Type: Game Export"
        puts
        view_save_game_info(nil, disk_path: path_to_disk)
        puts ".. Copy which games? Usage: -slot [1/2/3] -games 24,39,48"
        valid_input = false
        until valid_input
            params = get_user_input.split(" ")

            exit if params.first == "exit" || params.first == "quit"

            next if pv.missing_or_no_params?(params, 4, [%w(-slot -games)], reason: "Usage: -slot 3 -games 1,13,27", exact: true)

            slot_val = params[params.index("-slot")+1]
            game_val = params[params.index("-games")+1]&.split(",")&.uniq

            next if pv.slot_num_invalid?([slot_val])
            next if pv.value_nil?(game_val)
            next if pv.ids_incorrect?(game_val, (1..50))

            valid_input = true
        end

        copy_games_to_save(nil, slot_val, game_val, disk_drop: path_to_disk)
    else
        fail_with_reason(reason: "UFODISK type unknown! (Press enter to exit)")
        get_user_input
        exit
    end
end

# filter out any save info not to copy
def filter_data(game_data)
    filtered_terms = [
        "randSortOrder",            # saves track random sort order
        "HS NAME PREV",             # hiscores previous input
        "18_customLevel",           # do not export BK custom levels unless explicitly stated
    ]

    filter = game_data.select do |key, _v| 
        filtered_terms.any? do |term|
            key.include?(term) 
        end
    end

    filter.each do |k, _v|
        game_data.delete(k)
    end
    
    game_data
end

def search_for_game_in_data(game_data, game_id)
    JSON.parse(game_data).select { |key, _v| key.match(/\bgame#{game_id}[^0-9][\a-z]+|game0+[\a-z][^0-9]+#{game_id}\b/) }
end

def filepath_for_slot(num, just_folder: false)
    game_saves_location = "#{ENV['LOCALAPPDATA']}\\ufo50\\"
    return game_saves_location if just_folder == true

    "#{game_saves_location}save#{num}.ufo"
end

def save_data_to_slot(new_save_data, slot)
    save_tool_backup_path = "#{filepath_for_slot(nil, just_folder: true)}SaveEditorBackups\\"

    unless $optional_params[:no_backup] == false
        Dir.mkdir(save_tool_backup_path) unless File.exists?(save_tool_backup_path)
        FileUtils.cp(filepath_for_slot(slot), "#{save_tool_backup_path}\\save#{slot}_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.ufo")
    end

    save_path = $optional_params[:output].nil? ? filepath_for_slot(slot) : "#{filepath_for_slot(nil, just_folder: true)}#{$optional_params[:output]}"

    File.open(save_path, "w:UTF-8") do |file|
        file.write(new_save_data.force_encoding("UTF-8"))
    end

    puts "!! Games copied successfully, to:"
    puts "!! #{save_path}"
    puts "?? Open folder? (y/N)"
    input = get_user_input
    if input == "y" || input == "yes"
        system("explorer", "/select,#{filepath_for_slot(slot)}")
    else
        return
    end
end

def copy_data_to_slot(data_to_copy, data_to_delete, destination_data, destination_slot)
    begin
        data_to_delete.each do |key, _v|
            destination_data.delete(key)
        end

        destination_data = JSON.parse(destination_data).merge(data_to_copy)
        destination_data = JSON.generate(destination_data)

        new_save_data = encode_data(destination_data)

        save_data_to_slot(new_save_data, destination_slot)
    rescue => e
        puts "XX Copy failed! => #{e}"
    end
end

def user_confirms_overwrite?(game_num_list, dest_slot_num, bk: false)
    puts "!! WARNING: THIS WILL REPLACE YOUR SAVE IN SLOT #{dest_slot_num} FOR:"
    puts "!! #{game_num_list.map {|num| game_index[num.to_sym][:title]}.join(", ")}" if !bk
    puts "!! #{game_num_list.join(", ")}" if bk
    puts "!! PROCEED? (y/N)"
    input = get_user_input
    if input == "y" || input == "yes"
        return true
    else
        puts "!! Copy cancelled!"
        return false
    end
end

def copy_custom_levels_to_save(source_num, destination_num, custom_id_list, disk_drop: nil)
    source_data = disk_drop.nil? ? raise : disk_drop
    destination_data = decode_file(filepath_for_slot(destination_num))

    data_to_copy = {}
    destination_found_levels = []
    data_to_delete = {}

    custom_id_list.each_with_index do |id, index|
        key = "game18_customLevel#{id}"
        disk_drop_level = disk_drop["BK_Custom#{index+1}"]
        level_data = Hash.new
        level_data[key.to_sym] = disk_drop_level

        data_to_copy.merge!(level_data)

        search = JSON.parse(destination_data).select { |k,v| k == key }

        if search.empty?.!
            destination_found_levels.push(id)
            data_to_delete.merge!(search)
        end
    end

    if $optional_params[:overwrite] == true || destination_found_levels.empty?
        copy_data_to_slot(data_to_copy, data_to_delete, destination_data, destination_num)
    else
        copy_data_to_slot(data_to_copy, data_to_delete, destination_data, destination_num) if user_confirms_overwrite?(destination_found_levels, destination_num, bk: true)
    end
end

def copy_games_to_save(source_num, destination_num, game_list, disk_drop: nil)
    source_data = (disk_drop.nil?) ? decode_file(filepath_for_slot(source_num)) : decode_file(disk_drop)
    destination_data = decode_file(filepath_for_slot(destination_num))

    source_found_games = []
    destination_found_games = []
    data_to_copy = {}
    data_to_delete = {}

    game_list.each do |game_num|
        game = game_index[game_num.to_i.to_s.to_sym]
        internal_id = game[:id]

        search = search_for_game_in_data(source_data, internal_id)
        search = filter_data(search)

        if search.empty?.!
            source_found_games.push(game_num) 
            data_to_copy.merge!(search)
        end

        search = search_for_game_in_data(destination_data, internal_id)
        search = filter_data(search)

        if search.empty?.!
            destination_found_games.push(game_num)
            data_to_delete.merge!(search)
        end
    end

    if source_found_games.empty?
        fail_with_reason(reason: "No game data found in ufodisk for game ids: \n!! ##{game_list.join(", #")} (Press enter to exit)") if disk_drop != nil
        fail_with_reason(reason: "No game data found in slot #{source_num} for game ids: \n!! ##{game_list.join(", #")}") if disk_drop.nil?
        get_user_input if disk_drop.nil?.!
        return
    end

    puts "═══════════════════════════════════════"
    puts "!!  #{disk_drop.nil? ? "[SLOT #{source_num}]" : ".UFODISK"}      ==>      [SLOT #{destination_num}]  !!"
    puts "═══════════════════════════════════════"

    display_game_info_for_copy(data_to_copy, data_to_delete, source_found_games) unless $optional_params[:no_verify] == true

    if $optional_params[:overwrite] == true || destination_found_games.empty?
        copy_data_to_slot(data_to_copy, data_to_delete, destination_data, destination_num)
    else
        copy_data_to_slot(data_to_copy, data_to_delete, destination_data, destination_num) if user_confirms_overwrite?(source_found_games & destination_found_games, destination_num)
    end
end

def calculate_time(time_in_ms)
    return "EMPTY" if time_in_ms.nil?
    begin
        seconds = (time_in_ms/(1000)) % 60
        minutes = (time_in_ms/(1000*60)) % 60
        hours = time_in_ms/(1000*60*60)

        "#{hours.to_i.to_s.rjust(2, "0")}h:#{minutes.to_i.to_s.rjust(2, "0")}m:#{seconds.to_i.to_s.rjust(2, "0")}s"
    rescue
        "???"
    end
end

def get_completion_stats(game_data, id)
    {
        playTime: calculate_time(game_data["game0_gameTimeSum#{id}"]) || nil,
        hasGold: game_data["game0_goldTime#{id}"].nil?.!,
        hasCherry: game_data["game0_cherryTime#{id}"].nil?.!,
        hasGift: game_data["game0_gardenTime#{id}"].nil?.!,
    }
end

def display_title(title, limit)
    if title.length > limit
        "#{title[0...limit-3] + "..."}"
    else
        "#{title.ljust(limit, " ")}"
    end
end

def view_save_game_info(slot_num, disk_path: nil)
    game_data = disk_path.nil? ? decode_file(filepath_for_slot(slot_num)) : decode_file(disk_path)
    
    puts "╔══╣ #{disk_path.nil?.! ? "UFODSK" : "SLOT #{slot_num}"} ╠═════════════════════════════════╗"
    puts "║ NUM - TITLE             - PLAYTIME    - ⌂GC ║"
    (1..50).to_a.each do |game_num|
        print "  % Searching for: ##{game_num.to_s.rjust(2, "0")}\r" if $optional_params[:verbose]
        game = game_index[game_num.to_i.to_s.to_sym]
        internal_id = game[:id] 
        search = filter_data(search_for_game_in_data(game_data, internal_id))
        stats = get_completion_stats(search, internal_id)
        next if search.empty?
        puts "║ ##{game_num.to_s.rjust(2, "0")} - #{display_title(game[:title], 17)} - #{(stats[:playTime] == "EMPTY") ? ("-- EMPTY --") : (stats[:playTime])} - #{(stats[:hasGift]) ? "X" : "-"}#{(stats[:hasGold]) ? "X" : "-"}#{(stats[:hasCherry]) ? "X" : "-"} ║"
    end
    puts "╚═════════════════════════════════════════════╝"
end

def display_game_info_for_copy(source_game_data, dest_game_data, game_list)
    return nil if game_list.nil? || source_game_data.nil?

    game_data_stats = game_list.map do |game_num|
        game = game_index[game_num.to_i.to_s.to_sym]
        internal_id = game[:id]
        {
            "num"=>game_num,
            "filename"=>game[:filename],
            "title"=>game[:title],
            "source_completion"=>get_completion_stats(source_game_data, internal_id),
            "destin_completion"=>get_completion_stats(dest_game_data, internal_id),
        }
    end

    
    game_data_stats.each do |game|
        title = display_title(game["title"], 12)
        source_time = (game["source_completion"][:playTime] == "EMPTY") ? ("           ") : (game["source_completion"][:playTime])
        source_gold = (game["source_completion"][:hasGold]) ? ("[x] GOLD     ") : ("[ ] GOLD     ")
        source_cherry = (game["source_completion"][:hasCherry]) ? ("[x] CHERRY   ") : ("[ ] CHERRY   ")
        source_gift = (game["source_completion"][:hasGift]) ? ("[x] GIFT     ") : ("[ ] GIFT     ")
        destination_time = (game["destin_completion"][:playTime] == "EMPTY") ? ("           ") : (game["destin_completion"][:playTime])
        destination_gold = (game["destin_completion"][:playTime] == "EMPTY") ? ("══ EMPTY! ══ ") : ((game["destin_completion"][:hasGold]) ? ("[x] GOLD     ") : ("[ ] GOLD     "))
        destination_cherry = (game["destin_completion"][:playTime] == "EMPTY") ? ("             ") : ((game["destin_completion"][:hasCherry]) ? ("[x] CHERRY   ") : ("[ ] CHERRY   "))
        destination_gift = (game["destin_completion"][:playTime] == "EMPTY") ? ("             ") : ((game["destin_completion"][:hasGift]) ? ("[x] GIFT     ") : ("[ ] GIFT     "))
        puts "╔═╣ #{game["filename"]} ╠═╗       ╔═╣ #{game["filename"]} ╠═╗"
        puts "║ #{title} ║       ║ #{title} ║"
        puts "║ #{source_time}  ║       ║ #{destination_time}  ║"
        puts "║ #{source_gold}║  ==>  ║ #{destination_gold}║"
        puts "║ #{source_cherry}║       ║ #{destination_cherry}║"
        puts "║ #{source_gift}║       ║ #{destination_gift}║"
        puts "╚══════════════╝       ╚══════════════╝"
    end

    return true
end

def check_for_diskdrop
    if ARGV.empty?.! && File.exist?(ARGV[0]) && ARGV[0].end_with?(".ufodisk")
        puts_logo
        puts_disk_detected
        import_ufodisk(ARGV[0])
    else
        puts_logo
        fail_with_reason(reason: "Invalid import file! try *.ufodisk. (Press any key to exit)")
        get_user_input
        exit
    end
end

def main(logo: true)
    get_help(logo: logo)

    while ARGV.count == 0
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
