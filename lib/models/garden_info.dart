import 'package:flutter/material.dart';

enum GrowingSpace {
  balcony('Balcony', Icons.balcony),
  patio('Patio', Icons.deck),
  indoors('Indoors', Icons.chair),
  garden('Garden', Icons.yard);

  const GrowingSpace(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum SunExposure {
  fullSun('Full sun', '6+ hours of direct sun', Icons.wb_sunny),
  partialSun('Partial sun', '3 to 6 hours of direct sun', Icons.wb_cloudy),
  shade('Shade', 'Less than 3 hours of direct sun', Icons.cloud);

  const SunExposure(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

enum GardenSize {
  small('Small', 'A few pots', Icons.local_florist),
  medium('Medium', 'A couple of planters or beds', Icons.grass),
  large('Large', 'A whole yard or plot', Icons.park);

  const GardenSize(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

class GardenInfo {
  const GardenInfo({
    required this.name,
    required this.space,
    required this.sunExposure,
    required this.size,
    required this.plants,
  });

  final String name;
  final GrowingSpace space;
  final SunExposure sunExposure;
  final GardenSize size;
  final List<String> plants;
}
