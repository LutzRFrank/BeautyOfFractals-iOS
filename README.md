# Beauty of Fractals for iPhone, iPad, and Apple Watch

Beauty of Fractals is an interactive Mandelbrot and fractal explorer for iPhone
and iPad. Version 2.30 includes support for the fully opened iPhone Duo
display, with adaptive native bars, settings popovers, and safe-area-aware labels. The app also
offers natural touch navigation, Metal rendering, precise CPU deep zooms, PNG
export, and a compact Apple Watch companion.

## Version 2.30 (build 75)

Native action bars and two settings popovers replace the floating control drawer:

- Fractal, Skin & Quality provides mode, palette, quality, and power selection.
- Iterations & Effects provides the iteration budget, plateau tilt, and relevant
  skin controls, including Glass and the Metallic Dreams controls.
- Undo, zoom, Reset, favorites, help, render status, and export remain available.
- Supported iPhone Duo layouts adapt the bars to the display edge.
- Zoom/status labels respect system safe areas. Metal previews and CPU deep zooms
  both provide a render-status view.

The owner checked the new UI on iPhone and Duo before this shared version bump.
Dedicated partially folded layouts remain outside the advertised scope.

Release texts and handoff: `AppStore/Release-2.30.md` in the parent repository.

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
