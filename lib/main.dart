import 'package:flutter/material.dart';

import 'models/garden_info.dart';
import 'pages/garden_info_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geaux Farm',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.green)),
      home: const MyHomePage(title: 'My Gardens'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<GardenInfo> _gardens = [];

  Future<void> _addGarden() async {
    final garden = await Navigator.of(context).push<GardenInfo>(
      MaterialPageRoute(builder: (context) => const GardenInfoPage()),
    );
    if (garden == null || !mounted) {
      return;
    }
    setState(() => _gardens.add(garden));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${garden.name} submitted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _gardens.isEmpty
          ? const Center(
              child: Text('No gardens yet. Tap "Add garden" to submit one.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: _gardens.length,
              itemBuilder: (context, index) {
                final garden = _gardens[index];
                return Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: ListTile(
                    leading: Icon(
                      garden.space.icon,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(garden.name),
                    subtitle: Text(
                      '${garden.space.label} · '
                      '${garden.sunExposure.label} · '
                      '${garden.size.label}\n'
                      'Growing: ${garden.plants.join(', ')}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGarden,
        icon: const Icon(Icons.add),
        label: const Text('Add garden'),
      ),
    );
  }
}
