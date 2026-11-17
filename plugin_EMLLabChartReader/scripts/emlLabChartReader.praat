# ============================================================================
# EML LabChart Reader: open a LabChart binary export (.adibin) in Praat
# ============================================================================
# Purpose: Reads a LabChart "ADInstruments binary" export at full resolution,
#   in memory, with no intermediate file. Every channel keeps its recorded
#   units; channel names, units, scale, offset, range, sample rate, start
#   date and time and pre-trigger time come from the file itself. The script
#   leaves a combined multichannel Sound (one channel per LabChart channel, in
#   file order, on the file's own time axis) and a channel Table. Two optional
#   dialogs follow: extract chosen channels as separate Sounds, and export
#   chosen channels as Praat binary Sound files with a CSV of channel details.
#   Data formats 1 (64-bit float), 2 (32-bit float) and 3 (16-bit integer)
#   are read, with or without a time column.
# Date: 16 November 2026
# Version: 0.1.0
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab - www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell - created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
#
# License: GPL-3.0-or-later
# ============================================================================

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------
toolName$ = "EMLLabChartReader"
settingsVersion$ = "v1"

# ----------------------------------------------------------------------------
# Praat version check (APPENDIX_F S15)
# ----------------------------------------------------------------------------
vc_n = 1
vc_needs# = {6439}
vc_what$# = {"Praat 6.4.39 (PraatGen floor)"}
vc_kind$# = {"DIFFERS"}
vc_note$# = {"older builds were not checked with this script"}
vc_url$ = "https://www.fon.hum.uva.nl/praat/"
vc_prefPath$ = preferencesDirectory$ + "/eml_version_check.txt"

vc_max = 0
for vc_i to vc_n
    if vc_needs# [vc_i] > vc_max
        vc_max = vc_needs# [vc_i]
    endif
endfor

vc_forMin = 0
if fileReadable (vc_prefPath$)
    vc_prefTxt$ = readFile$ (vc_prefPath$)
    vc_k = index (vc_prefTxt$, "suppressed_for_min" + tab$)
    if vc_k > 0
        vc_rest$ = mid$ (vc_prefTxt$, vc_k + 19, 20) + newline$
        vc_forMin = number (left$ (vc_rest$,
            ... index (vc_rest$, newline$) - 1))
        if vc_forMin = undefined
            vc_forMin = 0
        endif
    endif
endif

vc_hits = 0
for vc_i to vc_n
    if praatVersion < vc_needs# [vc_i]
        vc_hits = vc_hits + 1
    endif
endfor

if vc_hits > 0 and vc_forMin < vc_max
    writeInfoLine: "This script uses ", vc_hits,
        ... " thing(s) your Praat does not have as this script expects."
    appendInfoLine: "You are running ", praatVersion$, "."
    appendInfoLine: ""
    for vc_i to vc_n
        if praatVersion < vc_needs# [vc_i]
            appendInfoLine: "  ", vc_what$# [vc_i]
            appendInfoLine: "      needs ", vc_needs# [vc_i],
                ... " -- ", vc_note$# [vc_i]
            appendInfoLine: ""
        endif
    endfor
    appendInfoLine: "Update here:  ", vc_url$

    beginPause: "Praat version"
        comment: "This script uses " + string$ (vc_hits) +
            ... " thing(s) your Praat handles differently."
        comment: "You are running " + praatVersion$ + "."
        comment: ""
        for vc_i to vc_n
            if praatVersion < vc_needs# [vc_i]
                comment: "- " + vc_what$# [vc_i] +
                    ... "  (needs " + string$ (vc_needs# [vc_i]) + ")"
                comment: "    " + vc_note$# [vc_i]
            endif
        endfor
        comment: ""
        comment: "Update at:  " + vc_url$
        comment: "(the full list is in the Info window, ready to copy)"
        boolean: "Check again next time", 1
    vc_clicked = endPause: "Quit", "Run anyway", 2, 0

    if check_again_next_time = 0
        writeFileLine: vc_prefPath$, "# EML PraatGen version check"
        appendFileLine: vc_prefPath$, "suppressed_for_min", tab$,
            ... string$ (vc_max)
        appendFileLine: vc_prefPath$, "suppressed_at_praat", tab$,
            ... string$ (praatVersion)
    endif
    if vc_clicked = 1
        exitScript: "Stopped. Update at ", vc_url$
    endif
endif

# ----------------------------------------------------------------------------
# Choose the file
# ----------------------------------------------------------------------------
adibinPath$ = chooseReadFile$ ("Read LabChart binary file")
if adibinPath$ = ""
    exitScript: "No file chosen."
endif
# One separator for every platform; Praat accepts "/" on Windows too.
adibinPath$ = replace$ (adibinPath$, "\", "/", 0)

settingsDir$ = preferencesDirectory$ + "/apps/" + toolName$
settingsPath$ = settingsDir$ + "/settings.txt"
@emlPGLabChartReaderLoadSettings: settingsPath$
oldExtract$ = emlPGLabChartReaderLoadSettings.extract$
oldExport$ = emlPGLabChartReaderLoadSettings.export$
oldCombined = emlPGLabChartReaderLoadSettings.combined

# ----------------------------------------------------------------------------
# Read and decode
# ----------------------------------------------------------------------------
@emlPGLabChartReaderRead: adibinPath$
soundId = emlPGLabChartReaderRead.soundId
tableId = emlPGLabChartReaderRead.tableId
nChannels = emlPGLabChartReaderRead.nChannels
baseName$ = emlPGLabChartReaderRead.baseName$
objectName$ = emlPGLabChartReaderRead.objectName$
adibinFolder$ = emlPGLabChartReaderRead.folder$

selectObject: tableId
titles$# = Get all texts in column: "title"
units$# = Get all texts in column: "unit"
@emlPGLabChartReaderKeys: titles$#
keys$# = emlPGLabChartReaderKeys.keys$#

# ----------------------------------------------------------------------------
# Extract dialog (default: don't extract)
# ----------------------------------------------------------------------------
beginPause: "Extract channels"
    comment: "The combined Sound has " + string$ (nChannels) + " channels."
    comment: "Tick channels to make each one a separate Sound."
    @emlPGLabChartReaderTickDialog: titles$#, units$#, keys$#, oldExtract$
extractClicked = endPause: "Don't extract", "Extract ticked", "Extract all", 1, 0
@emlPGLabChartReaderReadTicks: nChannels
extractTicks# = emlPGLabChartReaderReadTicks.ticked#
@emlPGLabChartReaderTickList: extractTicks#, keys$#
newExtract$ = emlPGLabChartReaderTickList.list$

extractedIds# = zero# (0)
if extractClicked > 1
    @emlPGLabChartReaderChosen: extractClicked, extractTicks#
    chosen# = emlPGLabChartReaderChosen.channels#
    for iChosen to size (chosen#)
        channel = chosen# [iChosen]
        @emlPGLabChartReaderChannelName: titles$# [channel], units$# [channel]
        @emlPGLabChartReaderChannelSound: soundId, channel,
            ... emlPGLabChartReaderChannelName.name$
        extractedIds# = combine# (extractedIds#, emlPGLabChartReaderChannelSound.id)
    endfor
    if size (chosen#) = 0
        appendInfoLine: "Extract: no channel was ticked, so nothing was extracted."
    else
        appendInfoLine: "Extracted ", size (chosen#), " channel(s) as separate Sounds."
    endif
endif

# ----------------------------------------------------------------------------
# Export dialog (default: don't export)
# ----------------------------------------------------------------------------
beginPause: "Export channels"
    comment: "Saves Praat binary Sound files at full precision,"
    comment: "with a CSV of channel details beside them."
    folder: "Export folder", adibinFolder$
    @emlPGLabChartReaderTickDialog: titles$#, units$#, keys$#, oldExport$
    boolean: "Also save one combined file", oldCombined
exportClicked = endPause: "Don't export", "Export ticked", "Export all", 1, 0
@emlPGLabChartReaderReadTicks: nChannels
exportTicks# = emlPGLabChartReaderReadTicks.ticked#
@emlPGLabChartReaderTickList: exportTicks#, keys$#
newExport$ = emlPGLabChartReaderTickList.list$
newCombined = also_save_one_combined_file

nFilesWritten = 0
if exportClicked > 1
    @emlPGLabChartReaderChosen: exportClicked, exportTicks#
    chosen# = emlPGLabChartReaderChosen.channels#
    if size (chosen#) = 0
        appendInfoLine: "Export: no channel was ticked, so no file was written."
    else
        exportFolder$ = replace$ (export_folder$, "\", "/", 0)
        if exportFolder$ = ""
            exportFolder$ = adibinFolder$
            appendInfoLine: "Export folder was empty; files go beside the .adibin file."
        endif
        if not folderExists (exportFolder$)
            createFolder: exportFolder$
        endif
        exportBase$ = exportFolder$ + "/" + objectName$
        soundFile$# = titles$#
        for iChannel to nChannels
            soundFile$# [iChannel] = ""
        endfor
        for iChosen to size (chosen#)
            channel = chosen# [iChosen]
            @emlPGLabChartReaderChannelName: titles$# [channel], units$# [channel]
            channelName$ = emlPGLabChartReaderChannelName.name$
            @emlPGLabChartReaderChannelSound: soundId, channel, channelName$
            tempId = emlPGLabChartReaderChannelSound.id
            @emlPGGenerateUniquePath: exportBase$ + "_" + channelName$ + ".Sound"
            outPath$ = emlPGGenerateUniquePath.result$
            selectObject: tempId
            Save as binary file: outPath$
            removeObject: tempId
            @emlPGLabChartReaderFileName: outPath$
            soundFile$# [channel] = emlPGLabChartReaderFileName.name$
            appendInfoLine: "Saved ", outPath$
            nFilesWritten = nFilesWritten + 1
        endfor
        combinedFile$ = ""
        if also_save_one_combined_file
            @emlPGGenerateUniquePath: exportBase$ + "_combined.Sound"
            outPath$ = emlPGGenerateUniquePath.result$
            if size (chosen#) = nChannels
                selectObject: soundId
                Save as binary file: outPath$
            else
                selectObject: soundId
                combinedId = Extract channels: chosen#
                Save as binary file: outPath$
                removeObject: combinedId
            endif
            @emlPGLabChartReaderFileName: outPath$
            combinedFile$ = emlPGLabChartReaderFileName.name$
            appendInfoLine: "Saved ", outPath$
            nFilesWritten = nFilesWritten + 1
        endif
        @emlPGGenerateUniquePath: exportBase$ + "_channels.csv"
        csvPath$ = emlPGGenerateUniquePath.result$
        @emlPGLabChartReaderWriteCsv: csvPath$, tableId, chosen#, soundFile$#, combinedFile$
        appendInfoLine: "Saved ", csvPath$
        nFilesWritten = nFilesWritten + 1
    endif
endif

# ----------------------------------------------------------------------------
# Remember choices (written only when one changed)
# ----------------------------------------------------------------------------
if newExtract$ <> oldExtract$ or newExport$ <> oldExport$ or newCombined <> oldCombined
    @emlPGLabChartReaderSaveSettings: settingsDir$, settingsPath$,
        ... "# " + toolName$ + " settings " + settingsVersion$, newExtract$, newExport$, newCombined
endif

# ----------------------------------------------------------------------------
# Summary and final selection
# ----------------------------------------------------------------------------
appendInfoLine: ""
appendInfoLine: "============================================"
appendInfoLine: "COMPLETE"
appendInfoLine: "============================================"
appendInfoLine: "Combined Sound:   ", objectName$, " (", nChannels, " channels)"
appendInfoLine: "Channel Table:    ", objectName$, "_channels"
appendInfoLine: "Extracted Sounds: ", size (extractedIds#)
appendInfoLine: "Files written:    ", nFilesWritten
appendInfoLine: "Warnings:         ", emlPGLabChartReaderRead.nWarnings
appendInfoLine: "============================================"

selectObject: soundId
plusObject: tableId
for iExtracted to size (extractedIds#)
    plusObject: extractedIds# [iExtracted]
endfor

# ============================================================================
# PROCEDURES
# ============================================================================

# Bit-layout constants of the file's numbers, stated once. A raw word sample
# is (signed 16-bit word) / .wordScale; adding .wordRange and taking mod
# .wordRange gives the unsigned word. 32-bit floats: 23 mantissa bits, 8
# exponent bits. 64-bit floats: the high 32 bits hold 20 mantissa bits and 11
# exponent bits. Called once at the start of the Read procedure.
procedure emlPGLabChartReaderBits
    .wordScale = 2 ^ 15
    .wordRange = 2 ^ 16
    .signBit32 = 2 ^ 31
    .range32 = 2 ^ 32
    .f32Mantissa = 2 ^ 23
    .f32Exponents = 2 ^ 8
    .f64HighMantissa = 2 ^ 20
    .f64Exponents = 2 ^ 11
endproc

# Unsigned 16-bit word k (1-based) of the raw word Sound.
procedure emlPGLabChartReaderU16: .wordsId, .k
    .value = (object [.wordsId] [1, .k] * emlPGLabChartReaderBits.wordScale
        ... + emlPGLabChartReaderBits.wordRange) mod emlPGLabChartReaderBits.wordRange
endproc

# Signed 32-bit integer at byte offset .byte (little-endian).
procedure emlPGLabChartReaderI32: .wordsId, .byte
    @emlPGLabChartReaderU16: .wordsId, .byte / 2 + 1
    .low = emlPGLabChartReaderU16.value
    @emlPGLabChartReaderU16: .wordsId, .byte / 2 + 2
    .value = .low + emlPGLabChartReaderBits.wordRange * emlPGLabChartReaderU16.value
    if .value >= emlPGLabChartReaderBits.signBit32
        .value = .value - emlPGLabChartReaderBits.range32
    endif
endproc

# IEEE 754 64-bit float at byte offset .byte (little-endian).
procedure emlPGLabChartReaderF64: .wordsId, .byte
    .k = .byte / 2 + 1
    @emlPGLabChartReaderU16: .wordsId, .k + 3
    .high = emlPGLabChartReaderU16.value
    # the top word holds the sign bit, 11 exponent bits and 4 mantissa bits
    .sign = floor (.high / emlPGLabChartReaderBits.wordScale)
    .topMantissa = emlPGLabChartReaderBits.wordRange / (2 * emlPGLabChartReaderBits.f64Exponents)
    .exponent = floor (.high / .topMantissa) mod emlPGLabChartReaderBits.f64Exponents
    .fraction = .high mod .topMantissa
    for .j to 3
        @emlPGLabChartReaderU16: .wordsId, .k + 3 - .j
        .fraction = .fraction * emlPGLabChartReaderBits.wordRange + emlPGLabChartReaderU16.value
    endfor
    if .exponent = emlPGLabChartReaderBits.f64Exponents - 1
        .value = undefined
    elsif .exponent = 0
        .value = .fraction * 2 ^ (-1074) * (1 - 2 * .sign)
    else
        .value = (.fraction + 2 ^ 52) * 2 ^ (.exponent - 1075) * (1 - 2 * .sign)
    endif
endproc

# Null-terminated text of at most .n bytes at byte offset .byte, read as
# Latin-1, trimmed of leading and trailing spaces.
procedure emlPGLabChartReaderText: .wordsId, .byte, .n
    .text$ = ""
    .done = 0
    for .i from 0 to .n / 2 - 1
        if .done = 0
            @emlPGLabChartReaderU16: .wordsId, .byte / 2 + 1 + .i
            .b1 = emlPGLabChartReaderU16.value mod 256
            .b2 = floor (emlPGLabChartReaderU16.value / 256)
            if .b1 = 0
                .done = 1
            else
                .text$ = .text$ + unicode$ (.b1)
                if .b2 = 0
                    .done = 1
                else
                    .text$ = .text$ + unicode$ (.b2)
                endif
            endif
        endif
    endfor
    while startsWith (.text$, " ")
        .text$ = right$ (.text$, length (.text$) - 1)
    endwhile
    while endsWith (.text$, " ")
        .text$ = left$ (.text$, length (.text$) - 1)
    endwhile
endproc

# ASCII-only copy of a text, for file names, CSV cells and settings.
procedure emlPGLabChartReaderAscii: .text$
    .result$ = ""
    for .i to length (.text$)
        .c$ = mid$ (.text$, .i, 1)
        .code = unicode (.c$)
        if .code >= 32 and .code <= 126
            .result$ = .result$ + .c$
        elsif .code = 181 or .code = 956
            .result$ = .result$ + "u"
        else
            .result$ = .result$ + "_"
        endif
    endfor
endproc

# Name part for objects and files: letters, digits and hyphens kept,
# "/" becomes "_per_", anything else "_", runs of "_" collapsed.
procedure emlPGLabChartReaderSafeName: .text$
    @emlPGLabChartReaderAscii: .text$
    .a$ = replace$ (emlPGLabChartReaderAscii.result$, "/", "_per_", 0)
    .keep$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-"
    .result$ = ""
    for .i to length (.a$)
        .c$ = mid$ (.a$, .i, 1)
        if index (.keep$, .c$) > 0
            .result$ = .result$ + .c$
        else
            .result$ = .result$ + "_"
        endif
    endfor
    while index (.result$, "__") > 0
        .result$ = replace$ (.result$, "__", "_", 0)
    endwhile
    if startsWith (.result$, "_")
        .result$ = right$ (.result$, length (.result$) - 1)
    endif
    if endsWith (.result$, "_")
        .result$ = left$ (.result$, length (.result$) - 1)
    endif
endproc

# Object and file name for one channel: <title>_<unit>.
procedure emlPGLabChartReaderChannelName: .title$, .unit$
    @emlPGLabChartReaderSafeName: .title$
    .name$ = emlPGLabChartReaderSafeName.result$
    if .name$ = ""
        .name$ = "channel"
    endif
    if .unit$ <> ""
        @emlPGLabChartReaderSafeName: .unit$
        .name$ = .name$ + "_" + emlPGLabChartReaderSafeName.result$
    endif
endproc

# One channel of the combined Sound as a new, renamed Sound.
procedure emlPGLabChartReaderChannelSound: .soundId, .channel, .name$
    selectObject: .soundId
    .id = Extract one channel: .channel
    Rename: .name$
endproc

# File name (without folder) and folder of a path.
procedure emlPGLabChartReaderFileName: .path$
    .name$ = right$ (.path$, length (.path$) - rindex (.path$, "/"))
    .folder$ = left$ (.path$, rindex (.path$, "/") - 1)
endproc

# ASCII keys for remembering ticks by channel title.
procedure emlPGLabChartReaderKeys: .titles$#
    .keys$# = .titles$#
    for .i to size (.titles$#)
        @emlPGLabChartReaderAscii: .titles$# [.i]
        .keys$# [.i] = emlPGLabChartReaderAscii.result$
    endfor
endproc

# Adds one tick box per channel to the open pause window. A box starts
# ticked when its title is in the remembered list (tab-delimited).
procedure emlPGLabChartReaderTickDialog: .titles$#, .units$#, .keys$#, .remembered$
    for .i to size (.titles$#)
        .label$ = "Channel " + string$ (.i)
        if .titles$# [.i] <> "" and .units$# [.i] <> ""
            .label$ = .label$ + " (" + .titles$# [.i] + ", " + .units$# [.i] + ")"
        elsif .titles$# [.i] <> ""
            .label$ = .label$ + " (" + .titles$# [.i] + ")"
        elsif .units$# [.i] <> ""
            .label$ = .label$ + " (" + .units$# [.i] + ")"
        endif
        .ticked = index (.remembered$, tab$ + .keys$# [.i] + tab$) > 0
        boolean: .label$, .ticked
    endfor
endproc

# Reads the tick boxes channel_1 ... channel_N set by the last pause window.
procedure emlPGLabChartReaderReadTicks: .n
    .ticked# = zero# (.n)
    for .i to .n
        .ticked# [.i] = channel_'.i'
    endfor
endproc

# Tab-delimited list of the ticked keys, for the settings file.
procedure emlPGLabChartReaderTickList: .ticked#, .keys$#
    .list$ = tab$
    for .i to size (.ticked#)
        if .ticked# [.i]
            .list$ = .list$ + .keys$# [.i] + tab$
        endif
    endfor
endproc

# Channel numbers chosen by a dialog: ticked ones (button 2) or all (button 3).
procedure emlPGLabChartReaderChosen: .clicked, .ticked#
    .channels# = zero# (0)
    for .i to size (.ticked#)
        if .clicked = 3 or .ticked# [.i]
            .channels# = combine# (.channels#, .i)
        endif
    endfor
endproc

# Remembered choices. Missing file or keys leave the defaults: nothing
# ticked, no combined file.
procedure emlPGLabChartReaderLoadSettings: .path$
    @emlPGLabChartReaderSettingKeys
    .extract$ = tab$
    .export$ = tab$
    .combined = 0
    if fileReadable (.path$)
        .lines$# = readLinesFromFile$# (.path$)
        for .i to size (.lines$#)
            .line$ = .lines$# [.i]
            if startsWith (.line$, emlPGLabChartReaderSettingKeys.extract$ + tab$)
                .extract$ = right$ (.line$, length (.line$) - length (emlPGLabChartReaderSettingKeys.extract$)) + tab$
            elsif startsWith (.line$, emlPGLabChartReaderSettingKeys.export$ + tab$)
                .export$ = right$ (.line$, length (.line$) - length (emlPGLabChartReaderSettingKeys.export$)) + tab$
            elsif startsWith (.line$, emlPGLabChartReaderSettingKeys.combined$ + tab$)
                .combined = number (right$ (.line$, length (.line$) - length (emlPGLabChartReaderSettingKeys.combined$ + tab$)))
                if .combined = undefined
                    .combined = 0
                endif
            endif
        endfor
    endif
endproc

# Names of the settings-file lines, stated once for reading and writing.
procedure emlPGLabChartReaderSettingKeys
    .extract$ = "extract_ticked"
    .export$ = "export_ticked"
    .combined$ = "export_combined"
endproc

# Writes the settings file (overwritten on purpose: it holds the last choices).
# One write call, because Praat 7 asks permission for each file action.
procedure emlPGLabChartReaderSaveSettings: .dir$, .path$, .header$, .extract$, .export$, .combined
    @emlPGLabChartReaderSettingKeys
    .appsDir$ = left$ (.dir$, rindex (.dir$, "/") - 1)
    if not folderExists (.appsDir$)
        createFolder: .appsDir$
    endif
    if not folderExists (.dir$)
        createFolder: .dir$
    endif
    .text$ = .header$ + newline$
    .text$ = .text$ + emlPGLabChartReaderSettingKeys.extract$ + left$ (.extract$, length (.extract$) - 1) + newline$
    .text$ = .text$ + emlPGLabChartReaderSettingKeys.export$ + left$ (.export$, length (.export$) - 1) + newline$
    .text$ = .text$ + emlPGLabChartReaderSettingKeys.combined$ + tab$ + string$ (.combined) + newline$
    writeFile: .path$, .text$
endproc

# CSV cell for a text: quoted when it holds a comma or a quote; ASCII only.
procedure emlPGLabChartReaderCsvText: .text$
    @emlPGLabChartReaderAscii: .text$
    .cell$ = emlPGLabChartReaderAscii.result$
    if index (.cell$, ",") > 0 or index (.cell$, """") > 0
        .cell$ = """" + replace$ (.cell$, """", """""", 0) + """"
    endif
endproc

# CSV cell for a number: blank when undefined.
procedure emlPGLabChartReaderCsvNumber: .value
    .cell$ = ""
    if .value <> undefined
        .cell$ = string$ (.value)
    endif
endproc

# Machine-readable CSV of the exported channels and the file header.
# Built in memory and written with one call (one Praat 7 permission prompt).
procedure emlPGLabChartReaderWriteCsv: .path$, .tableId, .channels#, .soundFile$#, .combinedFile$
    selectObject: .tableId
    .titles$# = Get all texts in column: "title"
    .units$# = Get all texts in column: "unit"
    .start$# = Get all texts in column: "recording_start"
    .scale# = Get all numbers in column: "scale"
    .offset# = Get all numbers in column: "offset"
    .high# = Get all numbers in column: "range_high"
    .low# = Get all numbers in column: "range_low"
    .rate# = Get all numbers in column: "sample_rate_Hz"
    .pre# = Get all numbers in column: "pretrigger_s"
    .format# = Get all numbers in column: "data_format"
    .samples# = Get all numbers in column: "n_samples"
    .text$ = "channel,title,unit,scale,offset,range_high,range_low,"
        ... + "sample_rate_Hz,n_samples,recording_start,pretrigger_s,data_format,"
        ... + "sound_file,combined_file,combined_channel" + newline$
    for .i to size (.channels#)
        .c = .channels# [.i]
        .row$ = string$ (.c)
        @emlPGLabChartReaderCsvText: .titles$# [.c]
        .row$ = .row$ + "," + emlPGLabChartReaderCsvText.cell$
        @emlPGLabChartReaderCsvText: .units$# [.c]
        .row$ = .row$ + "," + emlPGLabChartReaderCsvText.cell$
        .numbers# = {.scale# [.c], .offset# [.c], .high# [.c], .low# [.c], .rate# [.c], .samples# [.c]}
        for .j to size (.numbers#)
            @emlPGLabChartReaderCsvNumber: .numbers# [.j]
            .row$ = .row$ + "," + emlPGLabChartReaderCsvNumber.cell$
        endfor
        .row$ = .row$ + "," + .start$# [.c]
        @emlPGLabChartReaderCsvNumber: .pre# [.c]
        .row$ = .row$ + "," + emlPGLabChartReaderCsvNumber.cell$
        .row$ = .row$ + "," + string$ (.format# [.c])
        @emlPGLabChartReaderCsvText: .soundFile$# [.c]
        .row$ = .row$ + "," + emlPGLabChartReaderCsvText.cell$
        if .combinedFile$ = ""
            .row$ = .row$ + ",,"
        else
            @emlPGLabChartReaderCsvText: .combinedFile$
            .row$ = .row$ + "," + emlPGLabChartReaderCsvText.cell$ + "," + string$ (.i)
        endif
        .text$ = .text$ + .row$ + newline$
    endfor
    writeFile: .path$, .text$
endproc

# Counts samples whose stored exponent is all ones (infinity or not a number).
# .divisor isolates the exponent field of the bit pattern; .modulus is its
# number of values. Leaves the 0/1 flag Matrix for per-channel counts.
procedure emlPGLabChartReaderCountFlags: .valuesId, .divisor, .modulus
    selectObject: .valuesId
    .flagsId = Copy: "adibin_flags"
    selectObject: .flagsId
    Formula: ~ floor (self / .divisor) mod .modulus = .modulus - 1
    .count = Get sum
endproc

# Two-digit zero-padded number.
procedure emlPGLabChartReaderPad2: .value
    .text$ = right$ ("0" + string$ (.value), 2)
endproc

# Reads and decodes a LabChart binary file. Leaves the combined Sound and the
# channel Table; writes the header block, channel lines and warnings to the
# Info window.
procedure emlPGLabChartReaderRead: .path$
    .nWarnings = 0
    @emlPGLabChartReaderBits
    @emlPGLabChartReaderFileName: .path$
    .fileName$ = emlPGLabChartReaderFileName.name$
    .folder$ = emlPGLabChartReaderFileName.folder$
    .baseName$ = .fileName$
    if rindex (.fileName$, ".") > 1
        .baseName$ = left$ (.fileName$, rindex (.fileName$, ".") - 1)
    endif
    @emlPGLabChartReaderSafeName: .baseName$
    .objectName$ = emlPGLabChartReaderSafeName.result$
    if .objectName$ = ""
        .objectName$ = "labchart"
    endif

    .wordsId = Read Sound from raw 16-bit Little Endian file: .path$
    selectObject: .wordsId
    .nWords = Get number of samples
    .headerBytes = 68
    .channelBlockBytes = 96
    if .nWords < .headerBytes / 2
        removeObject: .wordsId
        exitScript: "This file is too short to be a LabChart binary file."
    endif
    @emlPGLabChartReaderText: .wordsId, 0, 4
    if emlPGLabChartReaderText.text$ <> "CFWB"
        removeObject: .wordsId
        exitScript: "This is not a LabChart binary file: it does not start with CFWB."
    endif
    @emlPGLabChartReaderI32: .wordsId, 4
    .version = emlPGLabChartReaderI32.value
    @emlPGLabChartReaderF64: .wordsId, 8
    .dt = emlPGLabChartReaderF64.value
    .dateParts# = zero# (5)
    for .i to 5
        @emlPGLabChartReaderI32: .wordsId, 12 + 4 * .i
        .dateParts# [.i] = emlPGLabChartReaderI32.value
    endfor
    @emlPGLabChartReaderF64: .wordsId, 36
    .seconds = emlPGLabChartReaderF64.value
    @emlPGLabChartReaderF64: .wordsId, 44
    .pretrigger = emlPGLabChartReaderF64.value
    @emlPGLabChartReaderI32: .wordsId, 52
    .nChannels = emlPGLabChartReaderI32.value
    @emlPGLabChartReaderI32: .wordsId, 56
    .nSamples = emlPGLabChartReaderI32.value
    @emlPGLabChartReaderI32: .wordsId, 60
    .hasTime = emlPGLabChartReaderI32.value <> 0
    @emlPGLabChartReaderI32: .wordsId, 64
    .format = emlPGLabChartReaderI32.value

    if .format < 1 or .format > 3
        removeObject: .wordsId
        exitScript: "Unknown LabChart data format ", .format, " (expected 1, 2 or 3)."
    endif
    if .nChannels < 1 or .nSamples < 1
        removeObject: .wordsId
        exitScript: "The file header reports no channels or no samples."
    endif
    if .dt = undefined or .dt <= 0
        removeObject: .wordsId
        exitScript: "The file header reports an invalid sample interval."
    endif

    .wordsPerValue# = {4, 2, 1}
    .wordsPerValue = .wordsPerValue# [.format]
    .formatName$# = {"64-bit float", "32-bit float", "16-bit integer"}
    .nCol = .nChannels + .hasTime
    .dataStartWord = (.headerBytes + .channelBlockBytes * .nChannels) / 2
    .neededWords = .dataStartWord + .nSamples * .nCol * .wordsPerValue
    if .nWords < .neededWords
        removeObject: .wordsId
        exitScript: "The file is shorter than its header says (", 2 * .nWords,
            ... " bytes, ", 2 * .neededWords, " needed). It may be truncated."
    endif

    @emlPGLabChartReaderPad2: .dateParts# [2]
    .month$ = emlPGLabChartReaderPad2.text$
    @emlPGLabChartReaderPad2: .dateParts# [3]
    .day$ = emlPGLabChartReaderPad2.text$
    @emlPGLabChartReaderPad2: .dateParts# [4]
    .hour$ = emlPGLabChartReaderPad2.text$
    @emlPGLabChartReaderPad2: .dateParts# [5]
    .minute$ = emlPGLabChartReaderPad2.text$
    .second$ = fixed$ (.seconds, 6)
    if .seconds < 10
        .second$ = "0" + .second$
    endif
    .start$ = string$ (.dateParts# [1]) + "-" + .month$ + "-" + .day$ + "T" +
        ... .hour$ + ":" + .minute$ + ":" + .second$
    .sampleRate = 1 / .dt

    writeInfoLine: "EML LabChart Reader: ", .fileName$
    appendInfoLine: "Folder:          ", .folder$
    appendInfoLine: "Data format:     ", .format, " (", .formatName$# [.format], "), version ", .version
    appendInfoLine: "Sample rate:     ", .sampleRate, " Hz (interval ", .dt, " s)"
    appendInfoLine: "Samples:         ", .nSamples, " per channel (",
        ... fixed$ (.nSamples * .dt, 3), " s)"
    appendInfoLine: "Recording start: ", .start$
    appendInfoLine: "Pre-trigger:     ", .pretrigger, " s"
    if .hasTime
        appendInfoLine: "Time column:     yes"
    else
        appendInfoLine: "Time column:     no"
    endif
    appendInfoLine: ""
    appendInfoLine: "Channel", tab$, "Title", tab$, "Unit", tab$, "Scale", tab$,
        ... "Offset", tab$, "Range high", tab$, "Range low"

    .tableId = Create Table with column names: .objectName$ + "_channels", .nChannels,
        ... "channel title unit scale offset range_high range_low sample_rate_Hz recording_start pretrigger_s data_format n_samples"
    .scale# = zero# (.nChannels)
    .offset# = zero# (.nChannels)
    for .c to .nChannels
        .block = .headerBytes + .channelBlockBytes * (.c - 1)
        @emlPGLabChartReaderText: .wordsId, .block, 32
        .title$ = emlPGLabChartReaderText.text$
        @emlPGLabChartReaderText: .wordsId, .block + 32, 32
        .unit$ = emlPGLabChartReaderText.text$
        @emlPGLabChartReaderF64: .wordsId, .block + 64
        .scale# [.c] = emlPGLabChartReaderF64.value
        @emlPGLabChartReaderF64: .wordsId, .block + 72
        .offset# [.c] = emlPGLabChartReaderF64.value
        @emlPGLabChartReaderF64: .wordsId, .block + 80
        .rangeHigh = emlPGLabChartReaderF64.value
        @emlPGLabChartReaderF64: .wordsId, .block + 88
        .rangeLow = emlPGLabChartReaderF64.value
        selectObject: .tableId
        Set numeric value: .c, "channel", .c
        Set string value: .c, "title", .title$
        Set string value: .c, "unit", .unit$
        Set numeric value: .c, "scale", .scale# [.c]
        Set numeric value: .c, "offset", .offset# [.c]
        Set numeric value: .c, "range_high", .rangeHigh
        Set numeric value: .c, "range_low", .rangeLow
        Set numeric value: .c, "sample_rate_Hz", .sampleRate
        Set string value: .c, "recording_start", .start$
        Set numeric value: .c, "pretrigger_s", .pretrigger
        Set numeric value: .c, "data_format", .format
        Set numeric value: .c, "n_samples", .nSamples
        appendInfoLine: .c, tab$, .title$, tab$, .unit$, tab$, .scale# [.c], tab$,
            ... .offset# [.c], tab$, .rangeHigh, tab$, .rangeLow
    endfor
    appendInfoLine: ""
    appendInfoLine: "The combined Sound holds every channel in its own unit; Praat stores no"
    appendInfoLine: "units in a Sound, so the units are in the channel Table and above."
    appendInfoLine: ""
    if .nWords > .neededWords
        appendInfoLine: "WARNING: the file has ", 2 * (.nWords - .neededWords),
            ... " bytes after the data; they were ignored."
        .nWarnings = .nWarnings + 1
    endif

    # Gather the stored values: one Matrix row per stored column, one Matrix
    # column per frame. The first word of value (row, col) is word
    # .dataStartWord + ((col - 1) * .nCol + row - 1) * .wordsPerValue + k,
    # k = 1 for the lowest word. A raw word sample is (signed word) / .wordScale;
    # adding .wordRange and taking mod .wordRange gives the unsigned word.
    .wordScale = emlPGLabChartReaderBits.wordScale
    .wordRange = emlPGLabChartReaderBits.wordRange
    .signBit = emlPGLabChartReaderBits.signBit32
    .lowId = 0
    .nonFinite = 0
    if .format = 3
        .valuesId = Create simple Matrix: "adibin_values", .nCol, .nSamples,
            ... ~ round (object [.wordsId] [1, .dataStartWord + (col - 1) * .nCol + row] * .wordScale)
    elsif .format = 2
        # unsigned 32-bit pattern from two words
        .valuesId = Create simple Matrix: "adibin_values", .nCol, .nSamples,
            ... ~ ((object [.wordsId] [1, .dataStartWord + ((col - 1) * .nCol + row - 1) * 2 + 2] * .wordScale
            ... + .wordRange) mod .wordRange) * .wordRange
            ... + (object [.wordsId] [1, .dataStartWord + ((col - 1) * .nCol + row - 1) * 2 + 1] * .wordScale
            ... + .wordRange) mod .wordRange
        .mant = emlPGLabChartReaderBits.f32Mantissa
        .nExp = emlPGLabChartReaderBits.f32Exponents
        @emlPGLabChartReaderCountFlags: .valuesId, .mant, .nExp
        .flagsId = emlPGLabChartReaderCountFlags.flagsId
        .nonFinite = emlPGLabChartReaderCountFlags.count
        selectObject: .valuesId
        Formula: ~ if floor (self / .mant) mod .nExp = .nExp - 1 then undefined
            ... else (if floor (self / .mant) mod .nExp = 0 then 2 ^ (-149) * (self mod .mant)
            ... else 2 ^ (floor (self / .mant) mod .nExp - 150) * (.mant + self mod .mant) fi)
            ... * (1 - 2 * floor (self / .signBit)) fi
    else
        # format 1: low 32 bits in one Matrix, high 32 bits in the other
        .lowId = Create simple Matrix: "adibin_low", .nCol, .nSamples,
            ... ~ ((object [.wordsId] [1, .dataStartWord + ((col - 1) * .nCol + row - 1) * 4 + 2] * .wordScale
            ... + .wordRange) mod .wordRange) * .wordRange
            ... + (object [.wordsId] [1, .dataStartWord + ((col - 1) * .nCol + row - 1) * 4 + 1] * .wordScale
            ... + .wordRange) mod .wordRange
        .valuesId = Create simple Matrix: "adibin_values", .nCol, .nSamples,
            ... ~ ((object [.wordsId] [1, .dataStartWord + ((col - 1) * .nCol + row - 1) * 4 + 4] * .wordScale
            ... + .wordRange) mod .wordRange) * .wordRange
            ... + (object [.wordsId] [1, .dataStartWord + ((col - 1) * .nCol + row - 1) * 4 + 3] * .wordScale
            ... + .wordRange) mod .wordRange
        .mant = emlPGLabChartReaderBits.f64HighMantissa
        .nExp = emlPGLabChartReaderBits.f64Exponents
        .range32 = emlPGLabChartReaderBits.range32
        @emlPGLabChartReaderCountFlags: .valuesId, .mant, .nExp
        .flagsId = emlPGLabChartReaderCountFlags.flagsId
        .nonFinite = emlPGLabChartReaderCountFlags.count
        selectObject: .valuesId
        Formula: ~ if floor (self / .mant) mod .nExp = .nExp - 1 then undefined
            ... else (if floor (self / .mant) mod .nExp = 0
            ... then 2 ^ (-1074) * ((self mod .mant) * .range32 + object [.lowId] [row, col])
            ... else (.mant * .range32 + (self mod .mant) * .range32 + object [.lowId] [row, col])
            ... * 2 ^ (floor (self / .mant) mod .nExp - 1075) fi)
            ... * (1 - 2 * floor (self / .signBit)) fi
    endif

    if .nonFinite > 0
        selectObject: .tableId
        .titles$# = Get all texts in column: "title"
        selectObject: .flagsId
        .flagSoundId = To Sound
        for .c to .nChannels
            selectObject: .flagSoundId
            .flagMean = Get mean: .c + .hasTime, 0, 0
            .count = round (.flagMean * .nSamples)
            if .count > 0
                appendInfoLine: "WARNING: channel ", .c, " (", .titles$# [.c], ") has ", .count,
                    ... " infinite or not-a-number samples; they are kept as undefined."
                .nWarnings = .nWarnings + 1
            endif
        endfor
        removeObject: .flagSoundId
    endif
    if .format <> 3
        removeObject: .flagsId
    endif

    selectObject: .valuesId
    .allId = To Sound
    Override sampling frequency: .sampleRate
    .firstTime = 0
    if .hasTime and .format <> 3
        .firstTime = object [.allId] [1, 1]
        if .firstTime = undefined
            .firstTime = 0
            appendInfoLine: "WARNING: the first time value is not a number; the first sample is placed at 0 s."
            .nWarnings = .nWarnings + 1
        endif
    endif
    selectObject: .allId
    .firstSampleTime = Get time from sample number: 1
    Shift times by: .firstTime - .firstSampleTime

    if .hasTime
        if .format = 3
            appendInfoLine: "Note: in 16-bit integer files the time column is stored like the data;"
            appendInfoLine: "      it was dropped without a check, and the first sample is at 0 s."
        else
            selectObject: .allId
            .timeId = Extract one channel: 1
            selectObject: .timeId
            Formula: ~ abs (self - x)
            .maxDeviation = Get maximum: 0, 0, "None"
            removeObject: .timeId
            if .maxDeviation = undefined or .maxDeviation > .dt / 2
                appendInfoLine: "WARNING: the file's time column differs from the time axis by up to ",
                    ... .maxDeviation, " s; the time column was dropped."
                .nWarnings = .nWarnings + 1
            endif
        endif
        selectObject: .allId
        .soundId = Extract channels: from_to# (2, .nCol)
        removeObject: .allId
    else
        .soundId = .allId
    endif
    selectObject: .soundId
    Rename: .objectName$
    selectObject: .soundId
    .startTime = Get start time
    .endTime = Get end time
    .scaled$ = ""
    for .c to .nChannels
        .scale = .scale# [.c]
        .offset = .offset# [.c]
        if .scale <> 1 or .offset <> 0
            selectObject: .soundId
            Formula (part): .startTime, .endTime, .c, .c, ~ (self + .offset) * .scale
            .scaled$ = .scaled$ + " " + string$ (.c)
        endif
    endfor
    if .scaled$ <> ""
        appendInfoLine: "WARNING: channel(s)", .scaled$, " were converted with (stored + offset) x scale,"
        appendInfoLine: "         because their scale is not 1 or their offset is not 0."
        .nWarnings = .nWarnings + 1
    endif

    removeObject: .wordsId, .valuesId
    if .lowId <> 0
        removeObject: .lowId
    endif
endproc

# ====================================================================
# EML library procedures - copied verbatim from the EML Praat Tools
# library (see header attribution). Included here so this script runs
# standalone; no plugin installation required.
# ====================================================================

# Copied from @emlGenerateUniquePath - eml-graphs-form.praat
# ----------------------------------------------------------------------------
# @emlPGGenerateUniquePath
# Appends ascending integer to filename until path is available.
# Arguments: .path$ (original desired path)
# Outputs: .result$ (available path)
# ----------------------------------------------------------------------------
procedure emlPGGenerateUniquePath: .path$
    if not fileReadable (.path$)
        .result$ = .path$
    else
        # Split into directory, base, extension
        .lastSlash = rindex (.path$, "/")
        if .lastSlash > 0
            .dir$ = left$ (.path$, .lastSlash)
            .filename$ = mid$ (.path$, .lastSlash + 1, length (.path$) - .lastSlash)
        else
            .dir$ = ""
            .filename$ = .path$
        endif

        .lastDot = rindex (.filename$, ".")
        if .lastDot > 0
            .base$ = left$ (.filename$, .lastDot - 1)
            .ext$ = mid$ (.filename$, .lastDot, length (.filename$) - .lastDot + 1)
        else
            .base$ = .filename$
            .ext$ = ""
        endif

        .counter = 1
        .result$ = .dir$ + .base$ + "_" + string$ (.counter) + .ext$
        while fileReadable (.result$)
            .counter = .counter + 1
            .result$ = .dir$ + .base$ + "_" + string$ (.counter) + .ext$
        endwhile
    endif
endproc
