# Changelog

## 0.1.0 - 16 November 2026 (beta)

- First release. Opens LabChart binary exports (`.adibin`) in Praat at full resolution, in memory, with no intermediate file.
- Reads data formats 1 (64-bit float), 2 (32-bit float) and 3 (16-bit integer), with or without a time column.
- Leaves a combined multichannel Sound and a channel Table. Optional dialogs extract chosen channels as separate Sounds and export chosen channels as Praat binary Sound files with a CSV of channel details.
- Remembers ticked channels and the combined-file choice between runs.
