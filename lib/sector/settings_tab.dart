part of 'sector_widget.dart';

extension _SettingsTab on _SectorWidgetState {
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DividerWithText(
            text: 'Allgemein',
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          // GUID (readonly)
          TextFormField(
            initialValue: sector.guid,
            decoration: const InputDecoration(labelText: 'GUID'),
            enabled: false,
          ),
          const SizedBox(height: 16),
          // Name
          ValueListenableBuilder<String>(
            valueListenable: sector.nameNotifier,
            builder: (context, name, _) {
              return TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (v) {
                  sector.name = v;
                },
              );
            },
          ),
          const SizedBox(height: 16),
          // Fassadenausrichtung
          const DividerWithText(
            text: 'Fassade',
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _orientationController,
                  decoration: InputDecoration(
                    labelText: 'Ausrichtung',
                    suffixText: '°',
                    errorText: _orientationError,
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v);
                    if (val == null || val < -180 || val > 180) {
                      _mutate(() {
                        _orientationError =
                            'Bitte Wert zwischen -180 und 180 eingeben';
                      });
                    } else {
                      _mutate(() {
                        _orientationError = null;
                        sector.orientation = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  // Open map dialog to pick two points
                  final result = await showDialog<Map<String, LatLng>>(
                    context: context,
                    builder: (_) => FacadeOrientationDialog(
                      initialAddress: sector.facadeAddress,
                      start: sector.facadeStart,
                      end: sector.facadeEnd,
                    ),
                  );
                  if (result != null) {
                    _mutate(() {
                      sector.facadeStart = result['start'];
                      sector.facadeEnd = result['end'];
                      // Calculate geodetic bearing between two coordinates
                      final lat1 = result['start']!.latitude * pi / 180;
                      final lat2 = result['end']!.latitude * pi / 180;
                      final lon1 = result['start']!.longitude * pi / 180;
                      final lon2 = result['end']!.longitude * pi / 180;
                      final dLon = lon2 - lon1;
                      final y = sin(dLon) * cos(lat2);
                      final x =
                          cos(lat1) * sin(lat2) -
                          sin(lat1) * cos(lat2) * cos(dLon);
                      var bearing = atan2(y, x) * 180 / pi;
                      bearing =
                          (bearing + 360) % 360 -
                          90; // Adjust to make 0 degrees point north
                      sector.orientation = bearing;
                      _orientationController.text = sector.orientation
                          .toStringAsFixed(1);
                    });
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Auf Karte wählen'),
              ),
            ],
          ),

          const DividerWithText(
            text: 'Sensoren',
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          SwitchListTile.adaptive(
            title: const Text('Helligkeit verwenden'),
            value: sector.useBrightness,
            onChanged: sector.useIrradiance
                ? (v) => _mutate(() {
                    sector.useBrightness = v;
                  })
                : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Globalstrahlung verwenden'),
            value: sector.useIrradiance,
            onChanged: sector.useBrightness
                ? (v) => _mutate(() {
                    sector.useIrradiance = v;
                  })
                : null,
          ),

          //Helligkeit
          if (sector.useBrightness)
            const DividerWithText(
              text: 'Helligkeit',
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          if (sector.useBrightness)
            TextFormField(
              initialValue: sector.brightnessAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Helligkeit',
                errorText: _brightnessAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.brightnessAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _brightnessAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _brightnessAddressError = null;
                  }
                });
              },
            ),
          if (sector.useBrightness) const SizedBox(height: 16),
          if (sector.useBrightness) 
            SwitchListTile.adaptive(
              title: const Text("Dynamische Verzögerungszeit"), 
              value: sector.brightnessDynamicDelay,
              onChanged: (v) => _mutate(() {
                sector.brightnessDynamicDelay = v;
                _validateDelayCurves();
              }),
            ),
          if (sector.useBrightness) const SizedBox(height: 16),
          if (sector.useBrightness && sector.brightnessDynamicDelay)
            _buildDelayEditor(isBrightness: true),
          if (sector.useBrightness && !sector.brightnessDynamicDelay)
            TextFormField(
              initialValue: sector.brightnessUpperThreshold?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Helligkeitsschwellwert Dunkel --> Hell',
                suffixText: 'Lux',
                errorText: _brightnessUpperThresholdError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0) {
                  _mutate(() {
                    _brightnessUpperThresholdError =
                        'Bitte gültigen Wert eingeben';
                  });
                } else if (val <= (sector.brightnessLowerThreshold ?? -1)) {
                  _mutate(() {
                    _brightnessUpperThresholdError =
                        'Muss grösser als der Schwellwert Hell --> Dunkel sein';
                  });
                } else {
                  _mutate(() {
                    _brightnessUpperThresholdError = null;
                    sector.brightnessUpperThreshold = val;
                  });
                }
              },
            ),
          if (sector.useBrightness && !sector.brightnessDynamicDelay)
            const SizedBox(height: 16),
          if (sector.useBrightness && !sector.brightnessDynamicDelay)
            TextFormField(
              initialValue: sector.brightnessUpperDelay?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Verzögerungszeit Dunkel --> Hell',
                suffixText: 's',
                errorText: _brightnessUpperDelayError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0 || val > 86400) {
                  _mutate(() {
                    _brightnessUpperDelayError = 'Bitte gültigen Wert eingeben';
                  });
                } else {
                  _mutate(() {
                    _brightnessUpperDelayError = null;
                    sector.brightnessUpperDelay = val;
                  });
                }
              },
            ),
          if (sector.useBrightness && !sector.brightnessDynamicDelay)
            const SizedBox(height: 16),
          if (sector.useBrightness && !sector.brightnessDynamicDelay)
            TextFormField(
              initialValue: sector.brightnessLowerThreshold?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Helligkeitsschwellwert Hell --> Dunkel',
                suffixText: 'Lux',
                errorText: _brightnessLowerThresholdError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0) {
                  _mutate(() {
                    _brightnessLowerThresholdError =
                        'Bitte gültigen Wert eingeben';
                  });
                } else if (val >= (sector.brightnessUpperThreshold ?? -1)) {
                  _mutate(() {
                    _brightnessLowerThresholdError =
                        'Muss kleiner als der Schwellwert Dunkel --> Hell sein';
                  });
                } else {
                  _mutate(() {
                    _brightnessLowerThresholdError = null;
                    sector.brightnessLowerThreshold = val;
                  });
                }
              },
            ),
          if (sector.useBrightness && !sector.brightnessDynamicDelay)
            const SizedBox(height: 16),
          if (sector.useBrightness && !sector.brightnessDynamicDelay)
            TextFormField(
              initialValue: sector.brightnessLowerDelay?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Verzögerungszeit Hell --> Dunkel',
                suffixText: 's',
                errorText: _brightnessLowerDelayError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0 || val > 86400) {
                  _mutate(() {
                    _brightnessLowerDelayError = 'Bitte gültigen Wert eingeben';
                  });
                } else {
                  _mutate(() {
                    _brightnessLowerDelayError = null;
                    sector.brightnessLowerDelay = val;
                  });
                }
              },
            ),

          //Globalstrahlung
          if (sector.useIrradiance)
            const DividerWithText(
              text: 'Globalstrahlung',
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          if (sector.useIrradiance)
            TextFormField(
              initialValue: sector.irradianceAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Globalstrahlung',
                errorText: _irradianceAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.irradianceAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _irradianceAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _irradianceAddressError = null;
                  }
                });
              },
            ),
          if (sector.useIrradiance) const SizedBox(height: 16),
          if (sector.useIrradiance) 
            SwitchListTile.adaptive(
              title: const Text("Dynamische Verzögerungszeit"), 
              value: sector.irradianceDynamicDelay,
              onChanged: (v) => _mutate(() {
                sector.irradianceDynamicDelay = v;
                _validateDelayCurves();
              }),
            ),
          if (sector.useIrradiance) const SizedBox(height: 16),
          if (sector.useIrradiance && sector.irradianceDynamicDelay)
            _buildDelayEditor(isBrightness: false),
          if (sector.useIrradiance && !sector.irradianceDynamicDelay)
            TextFormField(
              initialValue: sector.irradianceUpperThreshold?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Globalstrahlungsschwellwert Tief --> Hoch',
                suffixText: 'W/m²',
                errorText: _irradianceUpperThresholdError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0) {
                  _mutate(() {
                    _irradianceUpperThresholdError =
                        'Bitte gültigen Wert eingeben';
                  });
                } else if (val <= (sector.irradianceLowerThreshold ?? -1)) {
                  _mutate(() {
                    _irradianceUpperThresholdError =
                        'Muss grösser als der Schwellwert Hoch --> Tief sein';
                  });
                } else {
                  _mutate(() {
                    _irradianceUpperThresholdError = null;
                    sector.irradianceUpperThreshold = val;
                  });
                }
              },
            ),
          if (sector.useIrradiance && !sector.irradianceDynamicDelay) const SizedBox(height: 16),
          if (sector.useIrradiance && !sector.irradianceDynamicDelay)
            TextFormField(
              initialValue: sector.irradianceUpperDelay?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Verzögerungszeit Tief --> Hoch',
                suffixText: 's',
                errorText: _irradianceUpperDelayError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0 || val > 86400) {
                  _mutate(() {
                    _irradianceUpperDelayError = 'Bitte gültigen Wert eingeben';
                  });
                } else {
                  _mutate(() {
                    _irradianceUpperDelayError = null;
                    sector.irradianceUpperDelay = val;
                  });
                }
              },
            ),
          if (sector.useIrradiance && !sector.irradianceDynamicDelay) const SizedBox(height: 16),
          if (sector.useIrradiance && !sector.irradianceDynamicDelay)
            TextFormField(
              initialValue: sector.irradianceLowerThreshold?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Globalstrahlungsschwellwert Hoch --> Tief',
                suffixText: 'W/m²',
                errorText: _irradianceLowerThresholdError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0) {
                  _mutate(() {
                    _irradianceLowerThresholdError =
                        'Bitte gültigen Wert eingeben';
                  });
                } else if (val >= (sector.irradianceUpperThreshold ?? -1)) {
                  _mutate(() {
                    _irradianceLowerThresholdError =
                        'Muss kleiner als der Schwellwert Tief --> Hoch sein';
                  });
                } else {
                  _mutate(() {
                    _irradianceLowerThresholdError = null;
                    sector.irradianceLowerThreshold = val;
                  });
                }
              },
            ),
          if (sector.useIrradiance && !sector.irradianceDynamicDelay) const SizedBox(height: 16),
          if (sector.useIrradiance && !sector.irradianceDynamicDelay)
            TextFormField(
              initialValue: sector.irradianceLowerDelay?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Verzögerungszeit Hoch --> Tief',
                suffixText: 's',
                errorText: _irradianceLowerDelayError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0 || val > 86400) {
                  _mutate(() {
                    _irradianceLowerDelayError = 'Bitte gültigen Wert eingeben';
                  });
                } else {
                  _mutate(() {
                    _irradianceLowerDelayError = null;
                    sector.irradianceLowerDelay = val;
                  });
                }
              },
            ),

          if (sector.useBrightness && sector.useIrradiance)
            const DividerWithText(
              text: 'Verknüpfung',
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          if (sector.useBrightness && sector.useIrradiance)
            DropdownButtonFormField(
              value: sector.brightnessIrradianceLink,
              decoration: const InputDecoration(
                labelText: 'Verknüpfung Helligkeit und Globalstrahlung',
              ),
              items: const [
                DropdownMenuItem(value: 'And', child: Text('Und')),
                DropdownMenuItem(value: 'Or', child: Text('Oder')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _mutate(() {
                  sector.brightnessIrradianceLink = v;
                });
              },
            ),
            const DividerWithText(
              text: 'Übdersteuerung',
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            TextFormField(
              initialValue: sector.onAutoAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Ein/Auto',
                errorText: _onAutoAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.onAutoAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _onAutoAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _onAutoAddressError = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: sector.onAutoBehavior,
              decoration: const InputDecoration(
                labelText: 'Verhalten bei logischer 1',
              ),
              items: const [
                DropdownMenuItem(value: 'On', child: Text('Ein')),
                DropdownMenuItem(value: 'Auto', child: Text('Auto')),
              ],
              onChanged: (value) {
                if (value == null) return;
                _mutate(() {
                  sector.onAutoBehavior = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: sector.offAutoAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Aus/Auto',
                errorText: _offAutoAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.offAutoAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _offAutoAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _offAutoAddressError = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: sector.offAutoBehavior,
              decoration: const InputDecoration(
                labelText: 'Verhalten bei logischer 1',
              ),
              items: const [
                DropdownMenuItem(value: 'Off', child: Text('Aus')),
                DropdownMenuItem(value: 'Auto', child: Text('Auto')),
              ],
              onChanged: (value) {
                if (value == null) return;
                _mutate(() {
                  sector.offAutoBehavior = value;
                });
              },
            ),

          const DividerWithText(
            text: 'Automatik',
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          SwitchListTile.adaptive(
            title: const Text('Lamellennachführung'),
            value: sector.louvreTracking,
            onChanged: (v) => _mutate(() {
              sector.louvreTracking = v;
            }),
          ),
          SwitchListTile.adaptive(
            title: const Text('Horizontbegrenzung'),
            value: sector.horizonLimit,
            onChanged: (v) => _mutate(() {
              sector.horizonLimit = v;
            }),
          ),
            const DividerWithText(
              text: 'Ausgänge',
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            TextFormField(
              initialValue: sector.heightAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Höhe',
                errorText: _heightAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.heightAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _heightAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _heightAddressError = null;
                  }
                });
              },
            ),
            if (sector.louvreTracking) 
            const SizedBox(height: 16),
            if (sector.louvreTracking) 
            TextFormField(
              initialValue: sector.louvreAngleAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Lamellenwinkel',
                errorText: _louvreAngleAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.louvreAngleAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _louvreAngleAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _louvreAngleAddressError = null;
                  }
                });
              },
            ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: sector.sunBoolAddress,
            decoration: InputDecoration(
              labelText: 'Gruppenadresse Sonne',
              errorText: _sunBoolAddressError,
            ),
            onChanged: (v) {
              _mutate(() {
                sector.sunBoolAddress = v;
                final parts = v.split('/');
                final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                if (parts.length != 3 ||
                    a == null ||
                    a < 0 ||
                    a > 31 ||
                    b == null ||
                    b < 0 ||
                    b > 7 ||
                    c == null ||
                    c < 0 ||
                    c > 255 ||
                    (a == 0 && b == 0 && c == 0)) {
                  _sunBoolAddressError =
                      'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                } else {
                  _sunBoolAddressError = null;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          // Remove button (match time program delete style)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Sektor löschen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayEditor({required bool isBrightness}) {
    final highColor = isBrightness ? Colors.orange : Colors.purple;
    final lowColor = isBrightness ? Colors.blue : Colors.teal;
    final xLabel = isBrightness ? 'Helligkeit' : 'Globalstrahlung';
    final xSuffix = isBrightness ? 'lx' : 'W/m²';

    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dynamische Verzögerungskurven',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final highEditor = _buildDelayCurveEditor(
                  title: isBrightness ? 'Hell' : 'Hoch',
                  color: highColor,
                  isHigh: true,
                  isBrightness: isBrightness,
                  xLabel: xLabel,
                  xSuffix: xSuffix,
                );
                final lowEditor = _buildDelayCurveEditor(
                  title: isBrightness ? 'Dunkel' : 'Tief',
                  color: lowColor,
                  isHigh: false,
                  isBrightness: isBrightness,
                  xLabel: xLabel,
                  xSuffix: xSuffix,
                );
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: highEditor),
                      const SizedBox(width: 12),
                      Expanded(child: lowEditor),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    highEditor,
                    const SizedBox(height: 12),
                    lowEditor,
                  ],
                );
              },
            ),
            if (_getDelayRelationError(isBrightness: isBrightness) != null) ...[
              const SizedBox(height: 8),
              Text(
                _getDelayRelationError(isBrightness: isBrightness)!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: _buildDelayChart(
                highColor: highColor,
                lowColor: lowColor,
                isBrightness: isBrightness,
                xLabel: xLabel,
                xSuffix: xSuffix,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayCurveEditor({
    required String title,
    required bool isHigh,
    required bool isBrightness,
    required Color color,
    required String xLabel,
    required String xSuffix,
  }) {
    final points = _getDelayList(isBrightness: isBrightness, isHigh: isHigh);
    final sortedPoints = [...points]
      ..sort((a, b) => a.brightness.compareTo(b.brightness));
    final xCtrls = _getDelayXCtrls(
      isBrightness: isBrightness,
      isHigh: isHigh,
    );
    final yCtrls = _getDelayYCtrls(
      isBrightness: isBrightness,
      isHigh: isHigh,
    );
    final xErrors = _getDelayXErrors(
      isBrightness: isBrightness,
      isHigh: isHigh,
    );
    final yErrors = _getDelayYErrors(
      isBrightness: isBrightness,
      isHigh: isHigh,
    );
    final canAdd = points.length < 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: canAdd
                  ? () => _addDelayPoint(
                        isHigh: isHigh,
                        isBrightness: isBrightness,
                      )
                  : null,
              icon: const Icon(Icons.add),
              label: Text(canAdd ? 'Punkt hinzufügen' : 'Max. 5 Punkte'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (points.isEmpty)
          const Text('Keine Punkte definiert.')
        else
          ...sortedPoints.map(
            (p) {
              final brightnessCtrl = xCtrls[p] ??
                  TextEditingController(text: _fmt(p.brightness));
              xCtrls[p] = brightnessCtrl;
              final secondsCtrl = yCtrls[p] ??
                  TextEditingController(text: _fmt(p.seconds));
              yCtrls[p] = secondsCtrl;
              return Padding(
                key: ValueKey(p),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: brightnessCtrl,
                        decoration: InputDecoration(
                          labelText: xLabel,
                          suffixText: xSuffix,
                          errorText: xErrors[p],
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (v) => _handleDelayPointChanged(
                          p,
                          isHigh: isHigh,
                          isBrightness: isBrightness,
                          isBrightnessField: true,
                          value: v,
                          controller: brightnessCtrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: secondsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Zeit',
                          suffixText: 's',
                          errorText: yErrors[p],
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (v) => _handleDelayPointChanged(
                          p,
                          isHigh: isHigh,
                          isBrightness: isBrightness,
                          isBrightnessField: false,
                          value: v,
                          controller: secondsCtrl,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeDelayPoint(
                        p,
                        isHigh: isHigh,
                        isBrightness: isBrightness,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Punkt entfernen',
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDelayChart({
    required Color highColor,
    required Color lowColor,
    required bool isBrightness,
    required String xLabel,
    required String xSuffix,
  }) {
    final highPoints = [
      ..._getDelayList(isBrightness: isBrightness, isHigh: true)
    ]..sort((a, b) => a.brightness.compareTo(b.brightness));
    final lowPoints = [
      ..._getDelayList(isBrightness: isBrightness, isHigh: false)
    ]..sort((a, b) => a.brightness.compareTo(b.brightness));

    final hasData = highPoints.isNotEmpty || lowPoints.isNotEmpty;
    final brightnessValues = <double>[
      ...highPoints.map((p) => p.brightness),
      ...lowPoints.map((p) => p.brightness),
    ];
    final secondsValues = <double>[
      ...highPoints.map((p) => p.seconds),
      ...lowPoints.map((p) => p.seconds),
    ];
    final minX = hasData ? brightnessValues.reduce(min) : 0.0;
    final rawMaxX = hasData ? brightnessValues.reduce(max) : 100.0;
    final maxX = rawMaxX > minX ? rawMaxX : minX + 1;
    final maxSeconds = hasData ? secondsValues.reduce(max) : 10.0;
    final maxY = max(maxSeconds * 1.2, 10);

    final bars = <LineChartBarData>[
      if (lowPoints.isNotEmpty)
        LineChartBarData(
          color: lowColor,
          isCurved: false,
          barWidth: 3,
          dotData: FlDotData(show: true),
          spots: lowPoints
              .map(
                (p) => FlSpot(p.brightness, p.seconds),
              )
              .toList(),
        ),
      if (highPoints.isNotEmpty)
        LineChartBarData(
          color: highColor,
          isCurved: false,
          barWidth: 3,
          dotData: FlDotData(show: true),
          spots: highPoints
              .map(
                (p) => FlSpot(p.brightness, p.seconds),
              )
              .toList(),
        ),
    ];

    if (bars.isEmpty) {
      bars.add(
        LineChartBarData(
          color: Colors.transparent,
          barWidth: 0,
          dotData: FlDotData(show: false),
          spots: const [FlSpot(0, 0)],
        ),
      );
    }

    return Stack(
      children: [
        LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: 0,
            maxY: double.parse(maxY.toStringAsFixed(1)),
            gridData: const FlGridData(show: true),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) {
                  return spots
                      .map(
                        (s) => LineTooltipItem(
                          'Helligkeit: ${s.x.toStringAsFixed(1)} lx\nZeit: ${s.y.toStringAsFixed(1)} s',
                          const TextStyle(color: Colors.black),
                        ),
                      )
                      .toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            bottomTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$xLabel [$xSuffix]'),
              ),
              axisNameSize: 28,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(right: 4),
                  child: Text('Zeit [s]'),
                ),
                axisNameSize: 28,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                ),
              ),
            ),
            lineBarsData: bars,
          ),
        ),
        if (!hasData)
          const Center(
            child: Text('Keine Punkte definiert'),
          ),
      ],
    );
  }
}
