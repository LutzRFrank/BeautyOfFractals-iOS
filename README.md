# Beauty of Fractals for iPhone, iPad, and Apple Watch

Beauty of Fractals is an interactive Mandelbrot and fractal explorer for iPhone
and iPad. Version 2.20 introduces initial support for the fully opened iPhone Duo
display, with adaptive controls and safe-area-aware status labels. The app also
offers natural touch navigation, Metal rendering, precise CPU deep zooms, PNG
export, and a compact Apple Watch companion.

## Version 2.20 (build 3)

Version 2.20 adds initial support for the fully opened iPhone Duo display:

- The collapsible phone controls expand with the available window width.
- Zoom and status labels respect the display's safe-area insets.
- Window resizing clears transient gesture state while preserving the fractal
  center and zoom.
- Metal and high-precision previews use the current view size and aspect ratio.

This first compatibility pass targets the fully opened display. Dedicated
partially folded layouts are not included. Visual simulator checks covered
portrait and opened landscape; fold transitions and physical-device interaction
still need validation before submission.

Release metadata and localized copy are maintained in the parent repository at
`AppStore/iOS-2.20-Release.md`.

## Deep-zoom features

The 2.11 iOS line brings the current Mac deep-zoom work to mobile:

- Guarded Extreme Precision based on 6xDouble reference calculations
- Adaptive reference anchor selection with coverage repair for difficult views
- Automatic iteration budgeting from the center orbit plus a reserve
- Manual Deep iteration range up to 250,000
- iCloud-synced favorites with precise coordinates, thumbnails, palette,
  quality, mode, and effective iteration counts
- Apple Watch render progress ring, final preview image, and zoom display

Selected Mandelbrot locations can be explored around 10^50x. Deeper results are
experimental and depend strongly on the chosen location and iteration budget.

The app renders and exports locally. It does not use accounts, ads, analytics,
or tracking. iCloud sync and Apple Watch transfer use Apple system services.

The shared project and privacy policy are available here:
https://github.com/LutzRFrank/BeautyOfFractals
