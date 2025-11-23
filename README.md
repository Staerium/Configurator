

# Konfigurator

Konfigurator is a Flutter app for creating and editing `.sunproj` (XML) projects that describe facade shading sectors and KNX bus addresses. The UI is German and runs on desktop, mobile, and the web.

## Key Capabilities

- Project lifecycle: start from scratch or open an existing `.sunproj`, detect unsaved changes, and save/save-as (web uses the File System Access API when available, otherwise downloads the file).
- General settings: pick latitude/longitude on a map (Esri World Imagery tiles with Nominatim search), choose the azimuth/elevation source (internet, KNX time, or KNX az/el) with DPT selection and timezone, and configure KNX connection types (Routing, Tunneling UDP/TCP) including IP, ports, multicast, and optional auto-reconnect.
- Sector editor: add/copy/paste/remove sectors, compute facade orientation from two map points, toggle horizon limit and louvre tracking, set sensor usage (brightness and irradiance), thresholds/delays with AND/OR linkage, sun/height/louvre addresses, and override on/off auto behaviors.
- Horizon tools: edit horizon and ceiling point tables (anchors at -90°/+90°), import CSV data per sector, and plot solar paths for a chosen date plus solstice curves and the live sun position.
- Louvre tracking: define slat geometry, angle limits for 0%/100%, minimum change and buffer, and preview the resulting angle.
- Time programs: build weekly time switch programs with 1-bit or 1-byte commands, weekday masks, time pickers, sliders, and KNX group address validation; copy/paste programs for reuse.
- Legal and attribution: in-app screen shows the MIT license, privacy policy, third-party licenses, and required Esri/Nominatim attributions. The home screen also includes a placeholder button for an upcoming Staerium server connection.

## Getting Started

1. Clone the repository and enter the project directory.
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app (pass your ArcGIS key as a dart-define if you have one):
   ```sh
   flutter run --dart-define=ARCGIS_API_KEY=<YOUR_ARCGIS_API_KEY>
   ```

## ArcGIS API Key

Map dialogs use Esri World Imagery. Provide a key via `--dart-define=ARCGIS_API_KEY=<YOUR_ARCGIS_API_KEY>` so tiles and attribution metadata can be loaded under your credentials (see `lib/config/map_tiles.dart`). Without the define, the app falls back to the public endpoint, which is suitable for quick tests only. Add the same define to your CI/build commands (`flutter build <platform> --dart-define=ARCGIS_API_KEY=...`).

## CSV Import (Horizont/Decke)

The horizon tab can import CSV files with sector-specific points. Each row must start with a sector number followed by `KurveUnten` (horizon) or `KurveOben` (ceiling) and then azimuth/elevation value pairs. After import you choose which sector ID to apply; locked anchor points at -90°/+90° are preserved.

## Project Structure

- `lib/main.dart` – app entry, navigation, XML load/save, and unsaved-change handling
- `lib/general.dart` – general settings and KNX connection forms
- `lib/sector/sector_widget.dart` – sector editor with horizon and louvre tabs
- `lib/facade_orientation_dialog.dart` – map-based facade orientation picker
- `lib/location_dialog.dart` – map-based location picker
- `lib/timeswitch.dart` – time program models and widgets
- `lib/config/map_tiles.dart` – Esri tile configuration and API key handling
- `lib/services/` – Esri attribution and Nominatim search helpers
- `lib/widgets/data_attribution.dart` – map attribution overlays
- `assets/` – app icon and embedded legal texts

## Main Dependencies

- `flutter_map`, `latlong2` – map UI and coordinates
- `file_picker`, `universal_html`, `file_system_access_api` – file import/export on desktop and web
- `flutter_typeahead`, `http` – address suggestions via Nominatim
- `fl_chart`, `solar_calculator` – solar path charting
- `flutter_svg` – louvre preview asset
- `url_launcher`, `xml`, `uuid`, `dart_pubspec_licenses`
- See `pubspec.yaml` for the full list.

## Usage Overview

1. Create or open a `.sunproj`.
2. Set location, azimuth/elevation source, timezone, and KNX connection details.
3. Add sectors, set orientation via map or manual entry, configure imputs/outputs, and optionally enable louvre tracking or horizon limiting.
4. Use the horizon tab to edit or import curves and validate them against solar paths; use the louvre tab to tune geometry.
5. Add time programs if needed.
6. Save the project; the window title shows `*` when changes are unsaved.

## License

MIT License. See `LICENSE.txt` for details.
