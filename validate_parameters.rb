class ValidateParameters
  def missing_or_no_params?(params, expected_count, expected_params, reason: 'Incorrect usage.', exact: false)
    if (params.count < expected_count) || ((params.count != expected_count) && exact) || expected_params.any? do |set|
      set.all? do |param|
        params.include?(param)
      end
    end.!
      fail_with_reason(reason: reason, error: false)
      return true
    end
    false
  end

  def slot_num_invalid?(slots, reason: 'Slot parameter should be 1, 2, or 3.')
    unless slots.all? { |val| %w[1 2 3].include?(val) }
      fail_with_reason(reason: reason)
      return true
    end
    false
  end

  def file_doesnt_exist_for_slots?(slots, reason: "Save file doesn't exist.")
    slots.each do |filenum|
      filepath = SaveFile.filepath_for_slot(filenum)
      unless File.exist?(filepath)
        fail_with_reason(reason: reason)
        return true
      end
    end
    false
  end

  def value_nil?(game_val, reason: 'No game ids listed. Example: (1,13,27)')
    if game_val.nil?
      fail_with_reason(reason: reason)
      return true
    end
    false
  end

  def ids_incorrect?(list, range, reason: 'One or more game ids incorrect: ')
    def vals_in_range?(vals, range)
      vals.all? do |num|
        range.to_a.include?(num.to_i)
      end
    end

    unless vals_in_range?(list, range)
      fail_with_reason(reason: "#{reason}#{list.join(', ')}")
      return true
    end
    false
  end

  def wrong_number_of_ids?(list, expected_count, reason: 'Incorret number of ids')
    if list.length != expected_count
      fail_with_reason(reason: reason)
      return true
    end
    false
  end
end

def set_optional_params(params)
  if params.include?('--output')
    arg_index = params.index('--output') + 1
    OPTIONAL_PARAMS[:output] = params[arg_index]
  end

  OPTIONAL_PARAMS[:no_verify] = true if params.include?('--no-verify')
  OPTIONAL_PARAMS[:overwrite] = true if params.include?('--overwrite')
  OPTIONAL_PARAMS[:verbose] = true if params.include?('--verbose')
  OPTIONAL_PARAMS[:validate_bk] = false if params.include?('--no-validate')
end