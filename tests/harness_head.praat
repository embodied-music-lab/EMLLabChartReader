# Test harness: runs the reader procedure from the plugin script on one file
# and saves the combined Sound. Built by tests/run_tests.sh.
form: "t"
    sentence: "Path", ""
    sentence: "Out", ""
endform
settingsVersion$ = "v1"
@emlPGLabChartReaderRead: path$
s = emlPGLabChartReaderRead.soundId
selectObject: s
st = Get start time
t1 = Get time from sample number: 1
nc = Get number of channels
appendInfoLine: "RESULT channels ", nc, " t1 ", fixed$ (t1, 9), " start ", fixed$ (st, 9), " warnings ", emlPGLabChartReaderRead.nWarnings
Save as binary file: out$
