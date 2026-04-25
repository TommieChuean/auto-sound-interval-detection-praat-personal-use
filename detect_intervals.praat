############################################################
# Batch wrapper for /Users/tomchuean_/Desktop/test_3.praat
#
# Keeps the same click/speech detection logic and default
# thresholds, but reads one WAV file or a folder of WAV files.
############################################################

form Batch multi-trial click and speech onset detector
    sentence Input_path wavs
    sentence File_glob *.wav
    sentence Output_csv test3_results.csv
    positive Time_step 0.001
    positive Click_relative_threshold 0.45
    positive Click_onset_relative_threshold 0.08
    positive Min_click_gap 0.800
    positive Speech_window_start 1.0
    positive Speech_window_end 10.000
    positive Guard_before_next_click 0.100
    positive Speech_threshold 0.015
    positive Min_speech_duration 0.120
    positive Min_speech_hit_ratio 0.70
endform

procedure appendHeader
    filedelete 'output_csv$'
    header$ = "sound,trial,click_onset,speech_onset,interval,status" + newline$
    fileappend 'output_csv$' 'header$'
endproc

procedure processFile: .filePath$
    Read from file: .filePath$
    .soundID = selected ("Sound")
    .soundName$ = replace_regex$ (.filePath$, "^.*/", "", 0)

    selectObject: .soundID
    .duration = Get total duration
    .global_max = Get absolute extremum: 0, .duration, "None"

    if .global_max <= 0
        .line$ = """" + .soundName$ + """,0,NA,NA,NA,zero_amplitude" + newline$
        fileappend 'output_csv$' '.line$'
        selectObject: .soundID
        Remove
        goto endproc
    endif

    .click_threshold = .global_max * click_relative_threshold
    .click_onset_threshold = .global_max * click_onset_relative_threshold

    ############################################################
    # 1. Detect all click onsets
    ############################################################

    .nClicks = 0
    .last_click_time = -1000
    .t = 0

    while .t < .duration - time_step
        selectObject: .soundID
        .amp = Get absolute extremum: .t, .t + time_step, "None"

        if .amp >= .click_threshold and .t - .last_click_time >= min_click_gap
            .back_t = .t
            .keepGoing = 1

            while .keepGoing = 1 and .back_t > 0
                selectObject: .soundID
                .back_amp = Get absolute extremum: .back_t, .back_t + time_step, "None"

                if .back_amp < .click_onset_threshold
                    .keepGoing = 0
                else
                    .back_t = .back_t - time_step
                endif
            endwhile

            .click_onset = .back_t
            .nClicks = .nClicks + 1
            .clickTime_'.nClicks' = .click_onset
            .last_click_time = .t
            .t = .t + min_click_gap
        else
            .t = .t + time_step
        endif
    endwhile

    if .nClicks = 0
        .line$ = """" + .soundName$ + """,0,NA,NA,NA,click_not_found" + newline$
        fileappend 'output_csv$' '.line$'
        selectObject: .soundID
        Remove
        goto endproc
    endif

    ############################################################
    # 2. Detect speech onset after each click
    ############################################################

    for .i from 1 to .nClicks
        .click_time = .clickTime_'.i'
        .search_start = .click_time + speech_window_start
        .search_end_by_window = .click_time + speech_window_end

        if .i < .nClicks
            .next_i = .i + 1
            .next_click_time = .clickTime_'.next_i'
            .search_end_by_next_click = .next_click_time - guard_before_next_click

            if .search_end_by_window < .search_end_by_next_click
                .search_end = .search_end_by_window
            else
                .search_end = .search_end_by_next_click
            endif
        else
            if .search_end_by_window < .duration
                .search_end = .search_end_by_window
            else
                .search_end = .duration
            endif
        endif

        .speech_onset = -1
        .found_speech = 0

        if .search_end > .search_start + min_speech_duration
            .t = .search_start

            while .t < .search_end - min_speech_duration and .found_speech = 0
                .hit_count = 0
                .total_count = 0
                .small_t = .t

                while .small_t < .t + min_speech_duration
                    selectObject: .soundID
                    .small_amp = Get absolute extremum: .small_t, .small_t + time_step, "None"

                    if .small_amp >= speech_threshold
                        .hit_count = .hit_count + 1
                    endif

                    .total_count = .total_count + 1
                    .small_t = .small_t + time_step
                endwhile

                .hit_ratio = .hit_count / .total_count

                if .hit_ratio >= min_speech_hit_ratio
                    .speech_onset = .t
                    .found_speech = 1
                else
                    .t = .t + time_step
                endif
            endwhile
        endif

        .speechTime_'.i' = .speech_onset
    endfor

    ############################################################
    # 3. Append CSV rows
    ############################################################

    for .i from 1 to .nClicks
        .click_time = .clickTime_'.i'
        .speech_time = .speechTime_'.i'

        if .speech_time >= 0
            .interval = .speech_time - .click_time
            .line$ = """" + .soundName$ + """," + string$ (.i) + "," + fixed$ (.click_time, 6) + "," + fixed$ (.speech_time, 6) + "," + fixed$ (.interval, 6) + ",OK" + newline$
        else
            .line$ = """" + .soundName$ + """," + string$ (.i) + "," + fixed$ (.click_time, 6) + ",NA,NA,speech_not_found" + newline$
        endif

        fileappend 'output_csv$' '.line$'
    endfor

    selectObject: .soundID
    Remove

    label endproc
endproc

@appendHeader

if fileReadable (input_path$)
    @processFile: input_path$
elsif folderExists (input_path$)
    Create Strings as file list: "audioFiles", input_path$ + "/" + file_glob$
    .fileList = selected ("Strings")
    .fileCount = Get number of strings
    if .fileCount = 0
        exitScript: "No files matched ", input_path$ + "/" + file_glob$
    endif

    for .index from 1 to .fileCount
        selectObject: .fileList
        .name$ = Get string: .index
        @processFile: input_path$ + "/" + .name$
    endfor

    selectObject: .fileList
    Remove
else
    exitScript: "Input path not found: ", input_path$
endif

writeInfoLine: "Wrote test_3 batch results to ", output_csv$
