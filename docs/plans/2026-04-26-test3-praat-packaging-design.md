# Test3 Praat Packaging Design

## Goal

Update the personal-use Git project so its main workflow matches the latest Praat script based on the successful `test_3.praat` experiment.

## Chosen approach

Use a pure Praat package:

- Replace the old `detect_intervals.praat` with the batch-safe `test_3` variant.
- Keep a simple zsh wrapper that passes the known-good defaults.
- Rewrite the README around this current workflow.
- Leave Python spectrum/template experiments out of this repository.

## Output contract

The script writes one aggregate CSV with:

`sound,trial,click_onset,speech_onset,interval,status`

Times are in seconds on each audio file's own timeline.

## Rationale

The personal repository should be small and easy to run. The latest Praat amplitude detector currently works better for the tested recordings than the experimental Python alternatives, so the repo should present that path as the primary tool and keep the implementation dependency-free beyond Praat.
