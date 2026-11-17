# ============================================================================
# EML LabChart Reader: plugin registration
# ============================================================================
# Purpose: Runs when Praat starts. Adds "Read LabChart binary file..." to the
#   Open menu of the Objects window. The command runs
#   scripts/emlLabChartReader.praat from this plugin folder.
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

Add menu command: "Objects", "Open", "Read LabChart binary file...", "", 0, "scripts/emlLabChartReader.praat"
