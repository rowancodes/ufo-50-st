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
      if @code.length != 192
        fail_with_reason(reason: "#{@id}: Custom level code is not 192 characters")
        true
      end
    end

    def illegal_characters?
      diff = @code.chars.uniq - VALID_CHARS
      unless diff.empty?
        fail_with_reason(reason: "#{@id}: Illegal character in level code: #{diff.join(', ')}")
        true
      end
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