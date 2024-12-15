import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(StarterDictionary());
}

class StarterDictionary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Starter Dictionary',
      theme: ThemeData(primarySwatch: Colors.red),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer(); // Singleton instance
  static bool _isLooping = true; // Loop status

  static Future<void> playAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('jadeost.wav'));
      _audioPlayer.setReleaseMode(_isLooping ? ReleaseMode.loop : ReleaseMode.stop);
      await _audioPlayer.resume();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  static void toggleLoop() {
    _isLooping = !_isLooping;
    _audioPlayer.setReleaseMode(_isLooping ? ReleaseMode.loop : ReleaseMode.stop);
    print('Audio looping set to: $_isLooping');
  }

  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  static Future<void> disposeAudio() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      print('Error disposing audio: $e');
    }
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? pokemonImageUrl;

  @override
  void initState() {
    super.initState();
    fetchPokemonImage();
    Future.delayed(
      Duration(seconds: 3),
          () {
        Navigator.pushReplacementNamed(context, '/home');
      },
    );
  }

  Future<void> fetchPokemonImage() async {
    const apiUrl = 'https://pokeapi.co/api/v2/pokemon/1';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => pokemonImageUrl = data['sprites']['front_default']);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/jadebg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              pokemonImageUrl != null
                  ? Image.network(pokemonImageUrl!, height: 300, width: 300)
                  : CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Pokémon Dictionary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final starterPokemonIds = [
    1, 4, 7, 25, 152, 155, 158, 252, 255, 258, 387, 390, 393, 495, 498, 501, 650, 653, 656, 722, 725, 728, 810, 813, 816, 906, 909, 912
  ];
  final pokemonData = <int, Map<String, dynamic>>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    fetchPokemonData();
    AudioPlayerService.playAudio(); // Start audio
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Stop audio when app is not active
      AudioPlayerService.stopAudio();
    } else if (state == AppLifecycleState.resumed) {
      // Resume audio when app is active
      AudioPlayerService.playAudio();
    }
  }

  Future<void> fetchPokemonData() async {
    for (var id in starterPokemonIds) {
      final url = 'https://pokeapi.co/api/v2/pokemon/$id';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            pokemonData[id] = {
              'name': '${data['name'][0].toUpperCase()}${data['name'].substring(1)}',
              'image': data['sprites']['front_default'],
              'type': (data['types'] as List).map((t) => t['type']['name']).join(', '),
              'speciesUrl': data['species']['url'],
            };
          });
        }
      } catch (e) {
        print('Error fetching Pokémon $id: $e');
      }
    }
  }

  Color getBackgroundColor(String type) {
    if (type.contains('electric')) return Colors.yellow;
    if (type.contains('fire')) return Colors.red;
    if (type.contains('water')) return Colors.blue;
    if (type.contains('grass')) return Colors.green;
    return Colors.grey[200]!;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    AudioPlayerService.stopAudio();
    AudioPlayerService.disposeAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Home Page", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.loop),
            onPressed: () {
              setState(() {
                AudioPlayerService.toggleLoop();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/jadebg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: pokemonData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : GridView.builder(
          padding: EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: starterPokemonIds.length,
          itemBuilder: (context, index) {
            final id = starterPokemonIds[index];
            final data = pokemonData[id]!;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PokemonDetailPage(
                    name: data['name'],
                    type: data['type'],
                    image: data['image'],
                    speciesUrl: data['speciesUrl'],
                  ),
                ),
              ),
              child: Card(
                color: getBackgroundColor(data['type']),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Image.network(data['image'], height: 100, fit: BoxFit.cover),
                    SizedBox(height: 10),
                    Text(data['name'].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Type: ${data['type']}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PokemonDetailPage extends StatelessWidget {
  final String name;
  final String type;
  final String image;
  final String speciesUrl;

  PokemonDetailPage({required this.name, required this.type, required this.image, required this.speciesUrl});

  Future<List<String>> fetchEvolutionImages(String speciesUrl) async {
    try {
      final response = await http.get(Uri.parse(speciesUrl));
      if (response.statusCode == 200) {
        final speciesData = json.decode(response.body);
        final evolutionUrl = speciesData['evolution_chain']['url'];

        final evolutionResponse = await http.get(Uri.parse(evolutionUrl));
        if (evolutionResponse.statusCode == 200) {
          final evolutionData = json.decode(evolutionResponse.body);
          List<String> evolutionImages = [];
          var current = evolutionData['chain'];
          while (current != null) {
            final pokemonName = current['species']['name'];
            final pokemonResponse = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$pokemonName'));
            if (pokemonResponse.statusCode == 200) {
              final pokemonData = json.decode(pokemonResponse.body);
              evolutionImages.add(pokemonData['sprites']['front_default']);
            }
            current = (current['evolves_to'] as List).isNotEmpty ? current['evolves_to'][0] : null;
          }
          return evolutionImages;
        }
      }
    } catch (e) {
      print('Error fetching evolution chain: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('$name Details', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchEvolutionImages(speciesUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Failed to load evolution line.', style: TextStyle(color: Colors.white)));
          }

          final evolutionImages = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(image, height: 200),
                SizedBox(height: 20),
                Text('Name: $name', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 10),
                Text('Type: $type', style: TextStyle(fontSize: 18, color: Colors.white)),
                SizedBox(height: 20),
                Text('Evolution Line:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: evolutionImages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Image.network(evolutionImages[index]),
                    ),
                  ),
                ),
                SizedBox(height: 20
                ),
                Text(
                  'Would you like this Pokémon?',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}







