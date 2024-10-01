# UFO 50 Save Tool (or LX-III Save Tool)
# made by rowancodes
# ---------------------
# UFO 50 is a video game by Mossmouth, LLC @ https://50games.fun/

require "base64"
require "json"
require "fileutils"

$optional_params = {output: nil, no_verify: false, overwrite: false}

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
    puts "Optional:"
    puts "\t--output    =>\tspecify an output filename"
    puts "\t--no-verify =>\tdoes not verify game choice"
    puts "\t\t\tbefore continuing (be careful!)"
    puts "\t--overwrite =>\toverwrites existing game data"
    puts "\t\t\twithout asking (be careful!)"
    puts "v1.0.0"
end

def decode_file(filepath)
    input = File.open(filepath, "r:utf-8")
    line = input.readline.force_encoding("UTF-8")
    output = Base64.decode64(line).force_encoding("UTF-8")
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
end

def game_val_ok?(game_val)
    game_val_ok = game_val.all? do |game_num|
        (1..50).to_a.include?(game_num.to_i)
    end
end

def validate_parameters(user_input)
    params = user_input.split(" ")

    return if params.empty?

    set_optional_params(params)

    if    params.first == "help"
        get_help
        return 
    elsif params.first == "copy"
        # no/missing params
        if params.count == 1 || %w(-slot -to -games).all? { |param| params.include?(param) }.!
            fail_with_reason(reason: "Usage: copy -slot [1/2/3] -to [1/2/3] -games 1,13,27", error: false)
            return
        end

        game_val    = params[params.index("-games")+1]&.split(",")&.uniq
        slot_val    = params[params.index("-slot")+1]
        to_val      = params[params.index("-to")+1]

        # slot 1/2/3
        if [slot_val, to_val].all? { |val| %w(1 2 3).include?(val) }.!
            fail_with_reason(reason: "-slot & -to parameter should be 1, 2, or 3") 
            return
        end

        # file doesn't exist
        [slot_val, to_val].each do |filenum|
            filepath = filepath_for_slot(filenum)
            if File.exists?(filepath).!
                fail_with_reason(reason: "File does not exist: #{filepath}")
                return
            end
        end

        # no games listed
        if game_val.nil?
            fail_with_reason(reason: "No game ids listed. Example: (1,13,27)")
            return
        end

        # game ids incorrect
        if !game_val_ok?(game_val)
            fail_with_reason(reason: "One or more game ids incorrect: #{game_val.join(", ")}")
            return
        end

        # ALL GOOD !!!!!!!!!!!!!!!!
        copy_games_to_save(slot_val, to_val, game_val)
    elsif params.first == "export"

        # no/missing params
        if params.count == 1 || %w(-slot -games).all? { |param| params.include?(param) }.!
            fail_with_reason(reason: "Usage: export -slot [1/2/3] -games 17,35,49 (Optional: --output my_cool_disk)", error: false)
            return
        end

        game_vals    = params[params.index("-games")+1]&.split(",")
        slot_val    = params[params.index("-slot")+1]

        # slot 1/2/3
        if %w(1 2 3).include?(slot_val).!
            fail_with_reason(reason: "-slot parameter should be 1, 2, or 3") 
            return
        end

        # file doesn't exist
        if File.exists?(filepath_for_slot(slot_val)).!
            fail_with_reason(reason: "File does not exist: #{filepath}")
            return
        end

        # no games listed
        if game_vals.nil?
            fail_with_reason(reason: "No game ids listed. Example: (1,13,27)")
            return
        end

        # game ids incorrect
        if !game_val_ok?(game_vals)
            fail_with_reason(reason: "One or more game ids incorrect: #{game_vals.join(", ")}")
            return
        end

        export_games_to_disk(slot_val, game_vals)

    elsif params.first == "import"
        fail_with_reason(reason: "Drag and drop a .ufodisk file onto the exe!", error: false)
        fail_with_reason(reason: "or from command line:", error: false)
        fail_with_reason(reason: ".\\ufo-st.exe \"C:\\path\\to\\file\\my_cool_disk.ufodisk\"", error: false)
        return
    elsif params.first == "list"
        print_games_to_screen
        return
    elsif params.first == "view"
        if params.count != 2
            fail_with_reason(reason: "Usage: view [1/2/3]", error: false)
            return
        end

        # slot 1/2/3
        if %w(1 2 3).include?(params.last).!
            fail_with_reason(reason: "Parameter should be 1, 2, or 3") 
            return
        end

        view_save_game_info(params.last)
    elsif params.first == "exit" || params.first == "quit"
        puts "bye bye :3"
        exit
    else
        fail_with_reason(reason: "?? Unknown command: #{params.first}", error: false)
        return
    end 
end

def export_games_to_disk(slot_val, games_list)
    save_tool_disk_path = "#{filepath_for_slot(nil, just_folder: true)}SaveEditorDiskExports\\"
    Dir.mkdir(save_tool_disk_path) unless File.exists?(save_tool_disk_path)

    game_data = decode_file(filepath_for_slot(slot_val))

    found_games = []
    data_to_export = {}

    games_list.each do |game_num|
        game = game_index[game_num.to_i.to_s.to_sym]
        internal_id = game[:id]

        search = search_for_game_in_data(game_data, internal_id)
        search = filter_data(search)

        if search.empty?.!
            found_games.push(game_num) 
            data_to_export.merge!(search)
        end
    end

    if found_games.empty?
        fail_with_reason(reason: "No game data found in slot #{slot_val} for game ids: \n!! ##{games_list.join(", #")}")
    end

    profile_name = profile_name(game_data)

    begin
        data_to_export = JSON.generate(data_to_export)

        disk_data = encode_data(data_to_export)

        filename = nil
        if $optional_params[:output] != nil
            filename = $optional_params[:output].split(".").first + ".ufodisk"
        else
            filename = "#{profile_name[:ufoDiskExporterName]}-#{games_list.join("-")}.ufodisk"
        end

        File.open("#{save_tool_disk_path}#{filename}", "w:UTF-8") do |file|
            file.write(disk_data.force_encoding("UTF-8"))
        end
    
        puts "!! Games copied successfully, to:"
        puts "!! #{save_tool_disk_path}#{filename}"
        puts "!! Open folder? (y/N)"
        input = get_user_input
        if input == "y" || input == "yes"
            system("explorer", "/select,#{save_tool_disk_path}#{filename}")
        else
            return
        end
    rescue
        raise
    end
end

def profile_name(game_data)
    name = JSON.parse(game_data).select { |key, _v| key.include?("game0_profileName") }
    name.nil? ? {} : {ufoDiskExporterName: name["game0_profileName"]}
end

def import_ufodisk(path_to_disk)
    view_save_game_info(nil, from_disk: true, disk_path: path_to_disk)
    puts ".. Copy which games? Usage: -slot [1/2/3] -games 24,39,48"
    valid_input = false
    until valid_input
        params = get_user_input.split(" ")
        next if params.empty?

        # no/missing params
        if params.count == 1 || %w(-slot -games).all? { |param| params.include?(param) }.!
            fail_with_reason(reason: "Usage: -slot [1/2/3] -games 24,39,48", error: false)
            next
        end

        slot_val = params[params.index("-slot")+1]
        game_val = params[params.index("-games")+1]&.split(",")&.uniq

        if %w(1 2 3).include?(slot_val).!
            fail_with_reason(reason: "Choose slot: 1, 2, or 3") 
            next
        end

        # no games listed
        if game_val.nil?
            fail_with_reason(reason: "No game ids listed. Example: (1,13,27)")
            next
        end

        # game ids incorrect
        if !game_val_ok?(game_val)
            fail_with_reason(reason: "One or more game ids incorrect: #{game_val.join(", ")}")
            next
        end

        valid_input = true
    end

    copy_games_to_save(nil, slot_val, game_val, disk_drop: path_to_disk)
end

def kill_program(reason:)
    puts "#{reason}"
    exit
end

# filter out any save info not to copy
def filter_data(game_data)
    filtered_terms = [
        "randSortOrder",            # saves track random sort order
        "HS NAME PREV",             # hiscores previous input
        "ufoDiskExporterName",      # name i add for fun :3
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

def user_confirms_overwrite?(game_num_list, dest_slot_num)
    puts "!! WARNING: THIS WILL REPLACE YOUR SAVE IN SLOT #{dest_slot_num} FOR:"
    puts "!! #{game_num_list.map {|num| game_index[num.to_sym][:title]}.join(", ")}"
    puts "!! PROCEED? (y/N)"
    input = get_user_input
    if input == "y" || input == "yes"
        return true
    else
        puts "!! Copy cancelled!"
        return false
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
        fail_with_reason(reason: "No game data found in ufodisk for game ids: \n!! ##{game_list.join(", #")} (Press any key to exit)") if disk_drop != nil
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
        (puts "(Press any key to exit)"; get_user_input) if disk_drop.nil?.!
    else
        copy_data_to_slot(data_to_copy, data_to_delete, destination_data, destination_num) if user_confirms_overwrite?(source_found_games & destination_found_games, destination_num)
        (puts "(Press any key to exit)"; get_user_input) if disk_drop.nil?.!
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

def view_save_game_info(slot_num, from_disk: false, disk_path: nil)
    game_data = from_disk ? decode_file(disk_path) : decode_file(filepath_for_slot(slot_num))
    
    puts "╔══╣ #{from_disk ? "UFODSK" : "SLOT #{slot_num}"} ╠═════════════════════════════════╗"
    puts "║ NUM - TITLE             - PLAYTIME    - ⌂GC ║"
    (1..50).to_a.each do |game_num|
        game = game_index[game_num.to_i.to_s.to_sym]
        internal_id = game[:id] 
        search = search_for_game_in_data(game_data, internal_id)
        search = filter_data(search)
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