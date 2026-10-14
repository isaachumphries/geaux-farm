import '../../catalog/domain/plant.dart';
import 'compatibility.dart';

/// A catalog plant with its score for the current user and setup.
class ScoredPlant {
  const ScoredPlant(this.plant, this.compatibility);

  final Plant plant;
  final Compatibility compatibility;
}
