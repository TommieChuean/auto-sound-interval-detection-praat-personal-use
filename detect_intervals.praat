form Detect click to speech intervals
    sentence Input_path .
    sentence File_glob *.wav
    sentence Output_csv praat_results.csv
    real Click_threshold_db -14
    real Speech_threshold_db -30
    real Click_pitch_floor_hz 100
    real Speech_pitch_floor_hz 75
    real Click_min_silence_s 0.008
    real Speech_min_silence_s 0.05
    real Min_click_duration_s 0.003
    real Max_click_duration_s 0.100
    real Min_speech_duration_s 0.100
    real Min_gap_after_click_s 0.050
    real Search_window_s 8.0
    real Min_interval_s 0.120
    real Reject_shorter_than_s 0.100
    real Accept_longer_than_s 0.700
    real Early_short_interval_limit_s 0.800
    real Early_short_duration_limit_s 0.450
    real Speech_validation_window_s 0.350
    real Min_voiced_fraction 0.250
    real Min_sustain_ratio 0.550
    real Max_half_drop_db 8.0
    real Speech_refine_search_s 3.000
    real Speech_refine_window_s 0.080
    real Speech_refine_hop_s 0.020
    real Refine_voiced_fraction 0.450
    integer Refine_consecutive_windows 2
    real Refine_min_following_duration_s 0.350
    real Formant_probe_window_s 0.120
    real Formant_max_f1_jump_hz 180
    real Formant_max_f2_jump_hz 260
    integer Formant_consecutive_windows 2
    boolean Include_unmatched_clicks 0
endform

procedure appendHeader
    filedelete 'output_csv$'
    header$ = "file,trial_index,click_time_s,speech_onset_s,interval_s,status" + newline$
    fileappend 'output_csv$' 'header$'
endproc

procedure processFile: .filePath$
    Read from file: .filePath$
    .sound = selected ("Sound")
    .fileName$ = replace_regex$ (.filePath$, "^.*/", "", 0)

    selectObject: .sound
    To TextGrid (silences): click_pitch_floor_hz, 0.0, click_threshold_db, click_min_silence_s, min_click_duration_s, "silent", "click"
    .clickGrid = selected ("TextGrid")

    selectObject: .sound
    To TextGrid (silences): speech_pitch_floor_hz, 0.0, speech_threshold_db, speech_min_silence_s, min_speech_duration_s, "silent", "speech"
    .speechGrid = selected ("TextGrid")

    .trialIndex = 0
    .matchedCount = 0
    .lastMatchedSpeechInterval = 0

    selectObject: .clickGrid
    .clickIntervals = Get number of intervals: 1
    for .i from 1 to .clickIntervals
        selectObject: .clickGrid
        .clickLabel$ = Get label of interval: 1, .i
        if .clickLabel$ = "click"
            .clickStart = Get starting point: 1, .i
            .clickEnd = Get end point: 1, .i
            .clickDuration = .clickEnd - .clickStart
            if .clickDuration >= min_click_duration_s and .clickDuration <= max_click_duration_s
                .clickTime = (.clickStart + .clickEnd) / 2
                .speechFound = 0
                .clickOverlapsSpeech = 0

                selectObject: .speechGrid
                .speechIntervals = Get number of intervals: 1
                for .j from 1 to .speechIntervals
                    .speechLabel$ = Get label of interval: 1, .j
                    if .speechLabel$ = "speech"
                        .speechStart = Get starting point: 1, .j
                        .speechEnd = Get end point: 1, .j
                        if .clickTime >= .speechStart and .clickTime <= .speechEnd
                            .clickOverlapsSpeech = 1
                        endif
                    endif
                endfor

                if .clickOverlapsSpeech = 0
                    .searchStart = .clickTime + min_gap_after_click_s
                    .searchEnd = .clickTime + search_window_s
                    for .j from .lastMatchedSpeechInterval + 1 to .speechIntervals
                        if .speechFound = 0
                            .speechLabel$ = Get label of interval: 1, .j
                            if .speechLabel$ = "speech"
                                .speechStart = Get starting point: 1, .j
                                .speechEnd = Get end point: 1, .j
                                .speechDuration = .speechEnd - .speechStart
                                .interval = .speechStart - .clickTime
                                if .speechDuration >= min_speech_duration_s
                                    if .speechStart >= .searchStart and .speechStart <= .searchEnd
                                        if .interval >= min_interval_s
                                            .isSpeechLike = 0
                                            .acceptedSpeechStart = .speechStart

                                            if .speechDuration < reject_shorter_than_s
                                                .isSpeechLike = 0
                                            elsif .interval < early_short_interval_limit_s and .speechDuration < early_short_duration_limit_s
                                                .isSpeechLike = 0
                                            elsif .speechDuration >= accept_longer_than_s
                                                .isSpeechLike = 1
                                            else
                                                .validationEnd = .speechStart + speech_validation_window_s
                                                if .validationEnd > .speechEnd
                                                    .validationEnd = .speechEnd
                                                endif

                                                .windowDuration = .validationEnd - .speechStart
                                                if .windowDuration > 0.050
                                                    selectObject: .sound
                                                    Extract part: .speechStart, .validationEnd, "rectangular", 1, "no"
                                                    .speechPart = selected ("Sound")

                                                    selectObject: .speechPart
                                                    To Pitch: 0.0, speech_pitch_floor_hz, 500
                                                    .pitch = selected ("Pitch")
                                                    .voicedFrames = Count voiced frames
                                                    .totalFrames = Get number of frames
                                                    if .totalFrames > 0
                                                        .voicedFraction = .voicedFrames / .totalFrames
                                                    else
                                                        .voicedFraction = 0
                                                    endif

                                                    selectObject: .speechPart
                                                    .midpoint = .speechStart + (.windowDuration / 2)
                                                    .firstHalfRms = Get root-mean-square: .speechStart, .midpoint
                                                    .secondHalfRms = Get root-mean-square: .midpoint, .validationEnd
                                                    .sustainRatio = 0
                                                    .halfDropDb = 1000
                                                    if .firstHalfRms > 0
                                                        .sustainRatio = .secondHalfRms / .firstHalfRms
                                                        if .secondHalfRms > 0
                                                            .halfDropDb = 20 * log10 (.firstHalfRms / .secondHalfRms)
                                                        endif
                                                    endif

                                                    if .voicedFraction >= min_voiced_fraction
                                                        .isSpeechLike = 1
                                                    elsif .windowDuration >= 0.180
                                                        if .sustainRatio >= min_sustain_ratio and .halfDropDb <= max_half_drop_db
                                                            .isSpeechLike = 1
                                                        endif
                                                    endif

                                                    selectObject: .speechPart
                                                    plusObject: .pitch
                                                    Remove
                                                endif
                                            endif

                                            if .isSpeechLike = 1
                                                .refineSearchEnd = .speechStart + speech_refine_search_s
                                                if .refineSearchEnd > .speechEnd
                                                    .refineSearchEnd = .speechEnd
                                                endif
                                                .foundRefinedOnset = 0
                                                .voicedRun = 0
                                                .candidateSpeechStart = .speechStart
                                                .refineStart = .speechStart
                                                while .refineStart + speech_refine_window_s <= .refineSearchEnd
                                                    if .foundRefinedOnset = 0
                                                        .refineEnd = .refineStart + speech_refine_window_s
                                                        selectObject: .sound
                                                        Extract part: .refineStart, .refineEnd, "rectangular", 1, "no"
                                                        .refinePart = selected ("Sound")

                                                        selectObject: .refinePart
                                                        To Pitch: 0.0, speech_pitch_floor_hz, 500
                                                        .refinePitch = selected ("Pitch")
                                                        .refineVoicedFrames = Count voiced frames
                                                        .refineTotalFrames = Get number of frames
                                                        if .refineTotalFrames > 0
                                                            .refineVoicedFraction = .refineVoicedFrames / .refineTotalFrames
                                                        else
                                                            .refineVoicedFraction = 0
                                                        endif

                                                        if .refineVoicedFraction >= refine_voiced_fraction
                                                            if .voicedRun = 0
                                                                .candidateSpeechStart = .refineStart
                                                            endif
                                                            .voicedRun = .voicedRun + 1
                                                            if .voicedRun >= refine_consecutive_windows
                                                                if .speechEnd - .candidateSpeechStart >= refine_min_following_duration_s
                                                                    .acceptedSpeechStart = .candidateSpeechStart
                                                                    .foundRefinedOnset = 1
                                                                endif
                                                            endif
                                                        else
                                                            .voicedRun = 0
                                                        endif

                                                        selectObject: .refinePart
                                                        plusObject: .refinePitch
                                                        Remove
                                                    endif
                                                    .refineStart = .refineStart + speech_refine_hop_s
                                                endwhile

                                                if .foundRefinedOnset = 1
                                                    .formantSearchEnd = .refineSearchEnd - formant_probe_window_s
                                                    if .formantSearchEnd < .acceptedSpeechStart
                                                        .formantSearchEnd = .acceptedSpeechStart
                                                    endif
                                                    .bestFormantStart = .acceptedSpeechStart
                                                    .foundStableFormant = 0
                                                    .stableFormantRun = 0
                                                    .candidateFormantStart = .acceptedSpeechStart
                                                    .formantStart = .acceptedSpeechStart
                                                    while .formantStart <= .formantSearchEnd
                                                        if .foundStableFormant = 0
                                                            .formantEnd = .formantStart + formant_probe_window_s
                                                            selectObject: .sound
                                                            Extract part: .formantStart, .formantEnd, "rectangular", 1, "no"
                                                            .formantPart = selected ("Sound")

                                                            selectObject: .formantPart
                                                            To Formant (burg): 0.0, 5, 5500, 0.025, 50
                                                            .formant = selected ("Formant")

                                                            .probeStart = .formantStart + (formant_probe_window_s * 0.25)
                                                            .probeMid = .formantStart + (formant_probe_window_s * 0.50)
                                                            .probeEnd = .formantStart + (formant_probe_window_s * 0.75)

                                                            selectObject: .formant
                                                            .f1a = Get value at time: 1, .probeStart, "Hertz", "Linear"
                                                            .f1b = Get value at time: 1, .probeMid, "Hertz", "Linear"
                                                            .f1c = Get value at time: 1, .probeEnd, "Hertz", "Linear"
                                                            .f2a = Get value at time: 2, .probeStart, "Hertz", "Linear"
                                                            .f2b = Get value at time: 2, .probeMid, "Hertz", "Linear"
                                                            .f2c = Get value at time: 2, .probeEnd, "Hertz", "Linear"

                                                            .stableFormants = 0
                                                            if .f1a <> undefined and .f1b <> undefined and .f1c <> undefined
                                                                if .f2a <> undefined and .f2b <> undefined and .f2c <> undefined
                                                                    if abs (.f1a - .f1b) <= formant_max_f1_jump_hz and abs (.f1b - .f1c) <= formant_max_f1_jump_hz
                                                                        if abs (.f2a - .f2b) <= formant_max_f2_jump_hz and abs (.f2b - .f2c) <= formant_max_f2_jump_hz
                                                                            .stableFormants = 1
                                                                        endif
                                                                    endif
                                                                endif
                                                            endif

                                                            selectObject: .formantPart
                                                            plusObject: .formant
                                                            Remove

                                                            if .stableFormants = 1
                                                                if .stableFormantRun = 0
                                                                    .candidateFormantStart = .formantStart
                                                                endif
                                                                .stableFormantRun = .stableFormantRun + 1
                                                                if .stableFormantRun >= formant_consecutive_windows
                                                                    .bestFormantStart = .candidateFormantStart
                                                                    .foundStableFormant = 1
                                                                endif
                                                            else
                                                                .stableFormantRun = 0
                                                            endif
                                                        endif
                                                        .formantStart = .formantStart + speech_refine_hop_s
                                                    endwhile

                                                    if .foundStableFormant = 1
                                                        .acceptedSpeechStart = .bestFormantStart
                                                    endif
                                                endif
                                            endif

                                            if .isSpeechLike = 1
                                                .interval = .acceptedSpeechStart - .clickTime
                                                .trialIndex = .trialIndex + 1
                                                .matchedCount = .matchedCount + 1
                                                .lastMatchedSpeechInterval = .j
                                                line$ = """" + .fileName$ + """," + string$ (.trialIndex) + "," + fixed$ (.clickTime, 6) + "," + fixed$ (.acceptedSpeechStart, 6) + "," + fixed$ (.interval, 6) + ",ok" + newline$
                                                fileappend 'output_csv$' 'line$'
                                                .speechFound = 1
                                            endif
                                        endif
                                    endif
                                endif
                            endif
                        endif
                    endfor
                endif

                if include_unmatched_clicks and .speechFound = 0
                    .trialIndex = .trialIndex + 1
                    line$ = """" + .fileName$ + """," + string$ (.trialIndex) + "," + fixed$ (.clickTime, 6) + ",,," + "speech_not_found" + newline$
                    fileappend 'output_csv$' 'line$'
                endif
            endif
        endif
    endfor

    if .matchedCount = 0
        line$ = """" + .fileName$ + """,0,,,," + "no_match" + newline$
        fileappend 'output_csv$' 'line$'
    endif

    selectObject: .sound
    plusObject: .clickGrid
    plusObject: .speechGrid
    Remove
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

writeInfoLine: "Wrote results to ", output_csv$
