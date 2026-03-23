# Runi

Run visualiser app

## Philosophy

The sole purpose of the app is to allow users to generate a personalised artefact of their run. While run metrics can be helpful to analyse data to get better, it can also lead to pressure as the runs become way to analytical. This mentality often kills the joy and turns running into a means to an end, just another chore. This app serves as reminder that the act of running is a form of art, turning the data into joyous and abstract eye-candy visualisations.

———

## Current structure
(as of 23/03/2026)

The current state of the app doesn’t reflect the philosophy as much as it could. It’s a mix of what intended to be production ready features, diagnostics and learning materials. 

All these mixture of screens are put inside 2 tab groups: 
- Runs with the list of runs, visualisation view and a metrics view
- Learnings with all the different visualisation to try with a demo purely for development and learning purposes.

The whole Tab structure needs to be eliminated from the app before it hits the App Store. Almost everything that’s inside the Runs tab group will have its place in the production app but in a new more streamlined and cleaner structure. While the Learnings tab group is still useful, it has no place in the production app. It’ll be moved into a new separate app either as a complementary target of the Animations package or as a new Project based app, under a new Workspace umbrella that holds the production app and the new learnings app.

The rest of the document focuses on what should the App Store version of the app contain and how. The only concern of the demo (or learning) app is to be a separate entity to avoid leaking into production. There is no structural requirement for the demo app for now.

———

## New structure

The UI & UX of the app needs to reflect the philosophy, emphasising the core value and reduce everything else as much as possible. This means the single most important part of the app is the visualisation. That’s the main screen, the root of the app and since every other feature is just feeding into the visualisation they need to be accessed from there, not as standalone tabs. The following sections defines the fundamental functionality of the app with hints on the UI & UX for each.

### Visualiser

The visualiser is basically the canvas for the metal shaders, it’s the main attraction of the app, bringing the runs alive by displaying them as beautiful, abstract and joyful graphics. How each metric of a run is wired into a visualiser is implementation dependant. However, each visualisation can have some adjustable parameters to fine tune the end result.

The visualiser fills the full available space, which means the whole screen on iOS and the whole window on macOS / iPadOS / visionOS. Everything else on screen should be treated as a potential distraction firstly and only secondly as a feature. Whenever we’re about to add / change something on this screen, we should ask how important that feature is from the visualisation point of view and how frequently the user is going to interact with it. Keep the 80/20 rule in mind, it’s ok to have 80% of the app’s functionality slightly less convenient to access as most user will only use the most important 20% anyway.

The easily accessible features from the visualisation are:
- a compact Playback Control Strip displaying the name of the current run with a play toggle
- a button opening the Customisation Panel
- a button opening the Run Library
- a button to export and/or share the visualisation

**Visualiser entry point:** root of the app
**Visualisation Adjustment Form entry point:** Customisation Panel

### Playback

The player is the heart of the visualisation, it takes a run, processes its data and feeds it into the visualiser for each frame.
The player’s most important state is “what item is playing” and its most important control is to toggle the playback. Everything else is secondary: progress slider, repeat toggle, rewind and some more of the most basic info of the run like date, duration and distance.

The primary states and controls should always be visible in the root of the app regardless of device size as a Control Strip in the top or bottom toolbar. 
The secondary controls may appear in the toolbar next to the primary ones on big screens, or in a Control Panel sheet on smaller devices, resembling a media player’s UI.

While the data processing pipeline is a crucial part of the playback, it a tertiary functionality from the user’s POV. Most user would probably never really interfere with it, and only power users would customise it. Hence the pipeline customisation (run transformers, and run interpolation settings) don’t have to be prominent and can be buried to a deeper level of the app.

**Playback Control Strip entry point:** root of the app in toolbar (bottom or top depending on platform). 
**Playback Control Panel entry point:** tapping the compact control strip in the root of the app.
Data Processing Pipeline settings entry point: Customisation Panel

### Run Library

The visualiser needs runs to visualise. The runs can be either imported from GPX files or through the Strava API.

The Run Library displays all the imported and fetched runs in a list. The main purpose of the list is to select a run for the visualiser to play. Diving into the metrics of the run is not the goal of the app, so a run detail view is not the main interaction when selecting a run from the list. It’s a secondary action and the details of the run can stay very minimal and simple.

When the list empty, the main action should be to connect to Strava, but explain the (drag and drop0 GPX import possibility with a file browsing option.

When the app has no run to visualise (e.g. the very first time the user opens the app after install) it should automatically open the Run Library with the empty state recommending Strava connection or GPX import.

**Run Library entry point:** automatic when the app has no data or via the Run Library button from the app’s root view.

### Export / Share

A visualisation should be shareable. When the user is satisfied with the result of all the adjustments, the visualisation should be exportable to a video file. 

———

## Dictionary

The followings are the names of features, common functionalities or UI elements / screens of the app to align and understand each other better when communicating. These concepts or names should also be reflected in the code, file system and user facing information if necessary to avoid confusion.

- Visualiser: the canvas that displays visualisation
- Visualisation: graphics that is driven by run data
- Visualisation Adjustment Form: dedicated form of a visualisation to adjust its parameters
- Player: the engine feeding the Visualisations with processed running data
- Data Processing Pipeline: The players functionality to produce visualisation compatible data for each playback frame from the currently “playing” run’s metrics. From an implementation POV its the sum of zero or more Run Transformers and one Run Interpolator.
- Playback Control Strip: Compact grouped primary controls of the Playback
- Playback Control Panel: A detailed Playback UI, including primary and secondary info and controls 
- Customisation Panel: A UI that allows to either alter the Data Processing Pipeline or displays the Visualisation Adjustment Form
- Run Library: List of runs fetched from Strava or imported from GPX file.

———

## Future plans

### Persistence

Currently the app does not have any kind of persistence or state restoration whatsoever. It loads runs from Strava on demand and the every time the app starts the previously adjusted visualiser settings are also reset.

The fetched runs needs to be persisted on device via Swift Data. Not only the run details and metrics should be saved, but the run model also needs to contain the visualiser adjustments that were made while the run was loaded into the player. This means each visualisation needs to conform to the `Codable` protocol for state restoration. This way we could easily save it a raw data (or json string) with the run without having to create a model for each visualisation and their unique adjustable properties.

This feature is a must before the first official App Store release.

Persistence would allow us to easily create “Playlist” and flag runs as “Favourite”.
The implementation of fully persisting visualisation adjustments and data processing pipeline setups for runs also makes it possible to share a visualisation not just as a video but as data file (.runi extension) that can be opened via the app on other devices.

### Run to Visualisation wiring

How each metrics of a run is used by a visualisation is baked into the code. In the future though, it would be great to be able to adjust the “wiring” through the user interface. The difficult question is how, whether it should just be through specific `RunTransformers` or via exposed inlets of a visualisation.

### Concatenate / Merge Visualisations

The user should be able to select multiple runs to visualise at once. When selecting multiple runs:
- they can be concatenated after each other, for example to generate a single visualisation for a week of training
- or merge them with the same start time, for example to compare similar runs when using a path visualiser, or to create more intricate visualisations

Concatenation is quite straightforward as we can just append segments or even create a “Playlist” of runs. However a merged / overlapped version requires conceptual changes on how the player provides data, how visualisations accept/use data and whether or not a visualisation supports multiple overlapping data.

### Composable visualisations

Right now I implement standalone visualisations, however their implementation usually rely on a couple different techniques combined. For example the warp starts with a noise generation, then a fBM, then warping. The path visualiser uses the warp to distort the rendered path. Apart from some property adjustments they there isn’t much room for making more complex visualisations or change parts of the shader pipeline. For example it would be grate if the warp’s “value noise” generation could be swapped easily with a “vornoi noise”, or if the path could be distorted with different techniques or not at all. 

### Collaboration

Strava nicely puts people running together on the same map. However this is not a publicly available feature through their API. However with Swift Data & CloudKit Apple has a seamless “Collaboration” feature built into its systems. We can leverage this so users can share their runs in-app with collaboration which should merge their runs into a single visualisation. When accepting an invite, the app should scan for existing runs with overlapping date interval and/or gps data to automatically suggest to merge a run, but the user should also be able to manually select one from the list. Details to follow… 

Of course this feature heavily relies on the Persistence and Concatenate / Merge features.
