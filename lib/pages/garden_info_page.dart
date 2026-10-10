import 'package:flutter/material.dart';

import '../models/garden_info.dart';
import '../widgets/chunky.dart';

const _plantOptions = [
  'Tomatoes',
  'Peppers',
  'Okra',
  'Cucumbers',
  'Lettuce',
  'Basil',
  'Mint',
  'Strawberries',
  'Flowers',
];

const _stepCount = 5;
const _stepDuration = Duration(milliseconds: 300);

/// A step-by-step questionnaire about a garden, one question per page. Pops
/// with the submitted [GardenInfo], or with nothing if the user closes it.
class GardenInfoPage extends StatefulWidget {
  const GardenInfoPage({super.key});

  @override
  State<GardenInfoPage> createState() => _GardenInfoPageState();
}

class _GardenInfoPageState extends State<GardenInfoPage> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _step = 0;
  GrowingSpace? _space;
  SunExposure? _sunExposure;
  GardenSize? _size;
  final Set<String> _plants = {};

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _space != null,
    1 => _sunExposure != null,
    2 => _size != null,
    3 => _plants.isNotEmpty,
    _ => _nameController.text.trim().isNotEmpty,
  };

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: _stepDuration,
      curve: Curves.easeOut,
    );
  }

  void _continue() {
    if (_step < _stepCount - 1) {
      _goToStep(_step + 1);
      return;
    }
    Navigator.of(context).pop(
      GardenInfo(
        name: _nameController.text.trim(),
        space: _space!,
        sunExposure: _sunExposure!,
        size: _size!,
        plants: [
          for (final plant in _plantOptions)
            if (_plants.contains(plant)) plant,
        ],
      ),
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      _goToStep(_step - 1);
    }
  }

  Widget _buildStep({required String question, required Widget child}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const .fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 24,
        children: [
          Row(
            spacing: 12,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.eco, size: 32, color: scheme.primary),
              ),
              Flexible(
                child: Container(
                  padding: const .symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant, width: 2),
                    borderRadius: .circular(16),
                  ),
                  child: Text(
                    question,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: .w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSpaceStep() {
    return _buildStep(
      question: 'Where do you want to grow?',
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 12,
        children: [
          for (final space in GrowingSpace.values)
            OptionCard(
              label: space.label,
              icon: space.icon,
              selected: _space == space,
              onTap: () => setState(() => _space = space),
            ),
        ],
      ),
    );
  }

  Widget _buildSunStep() {
    return _buildStep(
      question: 'How much sun does it get?',
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 12,
        children: [
          for (final exposure in SunExposure.values)
            OptionCard(
              label: exposure.label,
              description: exposure.description,
              icon: exposure.icon,
              selected: _sunExposure == exposure,
              onTap: () => setState(() => _sunExposure = exposure),
            ),
        ],
      ),
    );
  }

  Widget _buildSizeStep() {
    return _buildStep(
      question: 'How much space do you have?',
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 12,
        children: [
          for (final size in GardenSize.values)
            OptionCard(
              label: size.label,
              description: size.description,
              icon: size.icon,
              selected: _size == size,
              onTap: () => setState(() => _size = size),
            ),
        ],
      ),
    );
  }

  Widget _buildPlantsStep() {
    return _buildStep(
      question: 'What do you want to grow? Pick as many as you like.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final plant in _plantOptions)
            OptionCard(
              label: plant,
              compact: true,
              selected: _plants.contains(plant),
              onTap: () => setState(() {
                if (!_plants.remove(plant)) {
                  _plants.add(plant);
                }
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return _buildStep(
      question: 'Last one! What should we call your garden?',
      child: TextField(
        key: const Key('gardenName'),
        controller: _nameController,
        textCapitalization: .words,
        textInputAction: .done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (_canContinue) {
            _continue();
          }
        },
        decoration: InputDecoration(
          hintText: 'Sunny Tomato Corner',
          border: OutlineInputBorder(borderRadius: .circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _back();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Padding(
                    padding: const .fromLTRB(4, 8, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _back,
                          tooltip: _step == 0 ? 'Close' : 'Back',
                          icon: Icon(
                            _step == 0 ? Icons.close : Icons.arrow_back,
                          ),
                        ),
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: (_step + 1) / _stepCount),
                            duration: _stepDuration,
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 14,
                                borderRadius: .circular(7),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSpaceStep(),
                        _buildSunStep(),
                        _buildSizeStep(),
                        _buildPlantsStep(),
                        _buildNameStep(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const .fromLTRB(16, 8, 16, 16),
                    child: ChunkyButton(
                      label: _step == _stepCount - 1 ? 'Finish' : 'Continue',
                      onPressed: _canContinue ? _continue : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
