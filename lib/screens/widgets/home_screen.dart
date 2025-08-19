import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart'; // Import login screen for logout navigation

void main() => runApp(const HomeScreen());

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Wiki',
      theme: ThemeData(
        primaryColor: Colors.red[900],
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.grey, fontSize: 16.0),
          headlineSmall: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
          bodyLarge: TextStyle(color: Colors.grey, fontSize: 16.0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.red[900],
          foregroundColor: Colors.white,
        ),
      ),
      home: const WikiHome(),
    );
  }
}


class WikiHome extends StatefulWidget {
  const WikiHome({super.key});

  @override
  _WikiHomeState createState() => _WikiHomeState();
}

class _WikiHomeState extends State<WikiHome> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mini Wiki'),
        leading: const Icon(Icons.account_box_rounded),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[900]!, Colors.red[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.grey[300]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 0.0),
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/arduin-chaos.png'),
                      radius: 60.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const Divider(height: 60.0, color: Colors.grey),
                  const Text(
                    'ARDUIN CHAOS',
                    style: TextStyle(
                      color: Colors.red,
                      letterSpacing: 2.0,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  const Text(
                    'Welcome to the Arduin Chaos Wiki! Explore the gaming world of Arduin Chaos, a passionate player known for epic adventures.',
                    style: TextStyle(color: Colors.grey, fontSize: 16.0),
                  ),
                  const SizedBox(height: 20.0),
                  _buildAnimatedButton(
                    context,
                    'Explore Games',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GamesPage()),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  _buildAnimatedButton(
                    context,
                    'About Arduin Chaos',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutPage()),
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

  Widget _buildAnimatedButton(BuildContext context, String text, VoidCallback onPressed) {
    return AnimatedScaleButton(
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Text(text, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[200],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[900]!, Colors.red[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/arduin-chaos.png'),
                  radius: 20.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Arduin Chaos Wiki',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit profile feature coming soon!')),
                    );
                  },
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.grey),
            title: const Text('Home', style: TextStyle(color: Colors.grey)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.games, color: Colors.grey),
            title: const Text('Games', style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GamesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.grey),
            title: const Text('About', style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Logout', style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => MaterialApp(
                    title: 'Mini Wiki Login',
                    theme: ThemeData(
                      primaryColor: Colors.red[900],
                      scaffoldBackgroundColor: Colors.grey[100],
                    ),
                    home: const LoginScreen(),
                  ),
                ),
                    (Route<dynamic> route) => false, // Remove all previous routes
              );
            },
          ),
        ],
      ),
    );
  }
}

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  _GamesPageState createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final List<Map<String, String>> games = const [
    {'name': 'Marvel Rivals', 'description': 'A fast-paced superhero PVP shooter.'},
    {'name': 'Monster Hunter World', 'description': 'An action RPG with epic monster battles.'},
    {'name': 'Hollow Knight', 'description': 'A challenging 2D Metroidvania adventure.'},
    {'name': 'Elden Ring', 'description': 'An open-world RPG by FromSoftware.'},
    {'name': 'Dark Souls', 'description': 'A challenging action RPG with intense combat.'},
    {'name': 'Blasphemous', 'description': 'A 2D indie Metroidvania with a dark adventure.'},
  ];

  List<Map<String, String>> filteredGames = [];
  final _searchController = TextEditingController();
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    filteredGames = List.from(games);
    _searchController.addListener(_filterGames);
  }

  void _filterGames() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredGames = games
          .where((game) => game['name']!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games Played'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[900]!, Colors.red[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search games...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15.0),
              itemCount: filteredGames.length,
              itemBuilder: (context, index) {
                final game = filteredGames[index];
                final name = game['name'] ?? 'Unknown Game';
                final description = game['description'] ?? 'No description available.';
                final isFavorite = _favorites.contains(name);
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    title: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(description, style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isFavorite) {
                            _favorites.remove(name);
                          } else {
                            _favorites.add(name);
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorite ? 'Removed $name from favorites' : 'Added $name to favorites',
                            ),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected: $name')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedScaleButton(
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add a new game to the list.')),
            );
          },
          tooltip: 'Add',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Arduin Chaos'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[900]!, Colors.red[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.grey[300]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arduin Chaos',
                  style: TextStyle(
                    color: Colors.red,
                    letterSpacing: 2.0,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20.0),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: const Text(
                      'Arduin Chaos is a passionate gamer and content creator, known for mastering challenging games like Elden Ring and Hollow Knight. Follow their epic adventures on social media!',
                      style: TextStyle(color: Colors.grey, fontSize: 16.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                AnimatedScaleButton(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Follow Arduin Chaos on X!')),
                      );
                    },
                    child: const Text('Follow on Social Media', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedScaleButton(
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact Arduin Chaos!')),
            );
          },
          tooltip: 'Contact',
          child: const Icon(Icons.email),
        ),
      ),
    );
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final Widget child;

  const AnimatedScaleButton({super.key, required this.child});

  @override
  _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}