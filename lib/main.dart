import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loggedIn = false;
  bool _loading = true;
  List<Map<String, dynamic>>? _preloadedCourses;

  @override
  void initState() {
    super.initState();
    _preloadCourses();
    _checkLogin();
  }

  Future<void> _preloadCourses() async {
    final data = await rootBundle.loadString('assets/golf_courses.json');
    final List<dynamic> jsonList = json.decode(data);
    setState(() {
      _preloadedCourses = jsonList.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _checkLogin() async {
    const storage = FlutterSecureStorage();
    final loggedIn = await storage.read(key: 'logged_in');
    setState(() {
      _loggedIn = loggedIn == 'true';
      _loading = false;
    });
  }

  void _onLogin() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'logged_in', value: 'true');
    setState(() {
      _loggedIn = true;
    });
  }

  void _onLogout() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'logged_in', value: 'false');
    setState(() {
      _loggedIn = false;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEFEDED),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF919194),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _loading || _preloadedCourses == null
          ? const Center(child: CircularProgressIndicator())
          : _loggedIn
              ? MainNavigation(onLogout: _onLogout, preloadedCourses: _preloadedCourses!)
              : LoginPage(onLogin: _onLogin),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final VoidCallback? onLogout;
  final List<Map<String, dynamic>> preloadedCourses;
  const MainNavigation({super.key, this.onLogout, required this.preloadedCourses});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      Center(child: Text('Home', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 16))),
      PlayPage(preloadedCourses: widget.preloadedCourses),
      Center(child: Text('Book', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 16))),
      YouPage(onLogout: widget.onLogout),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_golf),
            label: 'Play',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final void Function() onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    if (_formKey.currentState?.validate() ?? false) {
      await _storage.write(key: 'email', value: _emailController.text);
      await _storage.write(key: 'password', value: _passwordController.text);
      widget.onLogin();
    } else {
      setState(() { _error = 'Please enter valid credentials.'; });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Login', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => value != null && value.length >= 6 ? null : 'Min 6 characters',
                ),
                const SizedBox(height: 24),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const CircularProgressIndicator() : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class YouPage extends StatelessWidget {
  final VoidCallback? onLogout;
  const YouPage({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('You'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                if (onLogout != null) onLogout!();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')),
                );
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: const Center(
        child: Text('You', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    setState(() {
      _emailController.text = email ?? '';
      _passwordController.text = password ?? '';
      _loading = false;
    });
  }

  Future<void> _saveDetails() async {
    await _storage.write(key: 'email', value: _emailController.text);
    await _storage.write(key: 'password', value: _passwordController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveDetails,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}

class PlayPage extends StatefulWidget {
  final List<Map<String, dynamic>> preloadedCourses;
  final void Function()? onFavoritesChanged;
  const PlayPage({super.key, required this.preloadedCourses, this.onFavoritesChanged});
  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecentCourses();
    _loadFavorites();
  }
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favIds = prefs.getStringList('favorite_course_ids') ?? [];
    setState(() {
      favoriteCourses = favIds.map((id) => courses.firstWhere(
        (course) => course['id'].toString() == id,
        orElse: () => {},
      )).where((course) => course.isNotEmpty).toList();
    });
  }
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> filteredCourses = [];
  List<Map<String, dynamic>> favoriteCourses = [];
  List<Map<String, dynamic>> recentCourses = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool hasSearched = false;
  bool isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    courses = widget.preloadedCourses;
    filteredCourses = [];
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    _loadRecentCourses();
    _loadFavorites();
  }

  Future<void> _loadRecentCourses() async {
    // Use SharedPreferences for persistence
    final prefs = await SharedPreferences.getInstance();
    final recentIds = prefs.getStringList('recent_course_ids') ?? [];
    // Exclude favorites from recent searches
    final favoriteIds = favoriteCourses.map((fav) => fav['id']?.toString()).toSet();
    final nonFavoriteRecentIds = recentIds.where((id) => !favoriteIds.contains(id)).toList();
    // Always show 5 items: take the first 5, and if less than 5, fill with older non-favorite searches
    List<String> displayIds = [];
    for (var id in nonFavoriteRecentIds) {
      if (!displayIds.contains(id)) displayIds.add(id);
      if (displayIds.length == 5) break;
    }
    // If less than 5, fill with older non-favorite searches (from the end)
    if (displayIds.length < 5) {
      for (var id in nonFavoriteRecentIds.reversed) {
        if (!displayIds.contains(id)) displayIds.add(id);
        if (displayIds.length == 5) break;
      }
    }
    setState(() {
      recentCourses = displayIds.map((id) => courses.firstWhere(
        (course) => course['id'].toString() == id,
        orElse: () => {},
      )).where((course) => course.isNotEmpty).toList();
    });
  }

  Future<void> _addRecentCourse(Map<String, dynamic> course) async {
    final prefs = await SharedPreferences.getInstance();
    final recentIds = prefs.getStringList('recent_course_ids') ?? [];
    final id = course['id'].toString();
    recentIds.remove(id); // Remove if already exists
    recentIds.insert(0, id); // Add to front
    // Do not trim to 5 here; keep all for filtering and display
    await prefs.setStringList('recent_course_ids', recentIds);
    _loadRecentCourses();
    // Also reload favorites in case favorite status changed
    _loadFavorites();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      hasSearched = query.isNotEmpty;
      filteredCourses = courses.where((course) {
        final name = course['name']?.toLowerCase() ?? '';
        final city = (course['tags']?['addr:city']?.toLowerCase() ?? '');
        return name.contains(query) || city.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  labelText: 'Search courses',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: (_searchController.text.isNotEmpty || isSearchFocused)
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                            setState(() {
                              hasSearched = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onTap: () {
                  setState(() {
                    hasSearched = true;
                  });
                },
              ),
            ),
            if (favoriteCourses.isNotEmpty && !isSearchFocused && _searchController.text.isEmpty) ...[
              const SizedBox(height: 16),
              Text('Favorites', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              ...(() {
                final sortedFavorites = List<Map<String, dynamic>>.from(favoriteCourses);
                sortedFavorites.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
                return sortedFavorites.map((course) {
                  final cityRaw = course['tags']?['addr:city'];
                  final city = (cityRaw == null || cityRaw is! String || cityRaw.isEmpty || cityRaw == 'NaN') ? '-' : cityRaw;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: course['logo'] != null
                          ? Image.asset(
                              course['logo'],
                              width: (40.0.isNaN || 40.0.isInfinite || 40.0 <= 0) ? 32 : 40,
                              height: (40.0.isNaN || 40.0.isInfinite || 40.0 <= 0) ? 32 : 40,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.golf_course),
                      title: Row(
                        children: [
                          Expanded(child: Text(course['name'] ?? '')),
                          Icon(
                            favoriteCourses.any((fav) => fav['id']?.toString() == course['id']?.toString())
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: favoriteCourses.any((fav) => fav['id']?.toString() == course['id']?.toString())
                                ? Colors.red
                                : Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                      subtitle: Text(city.toString()),
                      onTap: () async {
                        await _addRecentCourse(course);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailPage(
                              course: course,
                              onFavoritesChanged: () {
                                _loadFavorites();
                                _loadRecentCourses();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList();
              })(),
            ],
            const SizedBox(height: 16),
            if (!isSearchFocused && _searchController.text.isEmpty) ...[
              Text('Recent Searches', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              ...recentCourses.where((course) {
                // Hide if course is a favorite
                final courseId = course['id']?.toString();
                return !favoriteCourses.any((fav) => fav['id']?.toString() == courseId);
              }).map((course) {
                final city = course['tags']?['addr:city'] ?? '-';
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: course['logo'] != null
                        ? Image.asset(course['logo'], width: 40, height: 40, fit: BoxFit.cover)
                        : const Icon(Icons.golf_course),
                    title: Text(course['name'] ?? ''),
                    subtitle: Text(city.toString()),
                    onTap: () async {
                      await _addRecentCourse(course);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetailPage(
                            course: course,
                            onFavoritesChanged: () {
                              _loadFavorites();
                              _loadRecentCourses();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
            if (isSearchFocused && _searchController.text.isNotEmpty) ...[
              ...filteredCourses.map((course) {
                final city = course['tags']?['addr:city'] ?? '-';
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: course['logo'] != null
                        ? Image.asset(course['logo'], width: 40, height: 40, fit: BoxFit.cover)
                        : const Icon(Icons.golf_course),
                    title: Text(course['name'] ?? ''),
                    subtitle: Text(city.toString()),
                    onTap: () async {
                      await _addRecentCourse(course);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetailPage(
                            course: course,
                            onFavoritesChanged: () {
                              _loadFavorites();
                              _loadRecentCourses();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}


class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;
  final void Function()? onFavoritesChanged;
  const CourseDetailPage({super.key, required this.course, this.onFavoritesChanged});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int selectedPlayerCount = 1;
  final List<String> gameTypes = ['Stroke Play', 'Match Play', 'Stableford'];
  String selectedGameType = 'Stroke Play';
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favIds = prefs.getStringList('favorite_course_ids') ?? [];
    setState(() {
      isFavorite = favIds.contains(widget.course['id'].toString());
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favIds = prefs.getStringList('favorite_course_ids') ?? [];
    final id = widget.course['id'].toString();
    setState(() {
      if (isFavorite) {
        favIds.remove(id);
        isFavorite = false;
      } else {
        favIds.add(id);
        isFavorite = true;
      }
    });
    await prefs.setStringList('favorite_course_ids', favIds);
    if (widget.onFavoritesChanged != null) {
      widget.onFavoritesChanged!();
    }
  }
  int selectedHoleIndex = 0;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final mainImage = course['mainImage'];
    final screenHeightRaw = MediaQuery.of(context).size.height;
    final screenHeight = (screenHeightRaw.isNaN || screenHeightRaw.isInfinite || screenHeightRaw <= 0)
        ? 600.0
        : screenHeightRaw;
    double safeHeight(double value, double fallback) {
      if (value.isNaN || value.isInfinite || value <= 0) return fallback;
      return value;
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Image.asset(
                      (mainImage != null && mainImage.isNotEmpty)
                          ? mainImage
                          : 'assets/courses/images/placeholder.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: safeHeight((screenHeight * 0.3).isNaN || (screenHeight * 0.3).isInfinite || (screenHeight * 0.3) <= 0 ? 200 : screenHeight * 0.3, 200),
                    ),
                    // Removed centered logo above the image. Only the logo to the right is shown.
                    // Back button and favorite icon
                    Positioned(
                      top: 60,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                              onPressed: _toggleFavorite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(course['name'] ?? '', style: Theme.of(context).textTheme.headlineMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final tags = course['tags'] as Map<String, dynamic>? ?? {};
                          final street = tags['addr:street'] ?? '';
                          final housenumber = tags['addr:housenumber'] ?? '';
                          final city = tags['addr:city'] ?? '';
                          String address = '';
                          if (street != '' || housenumber != '' || city != '') {
                            address = [street, housenumber].where((v) => v != '').join(' ');
                            if (city != '') {
                              address = address.isNotEmpty ? '$address, $city' : city;
                            }
                          }
                          return address.isNotEmpty
                              ? Text(address, style: Theme.of(context).textTheme.bodyMedium)
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                if (course['holes'] != null && course['holes'] is List && (course['holes'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...List.generate((course['holes'] as List).length, (i) {
                          final hole = (course['holes'] as List)[i];
                          String label;
                          if (hole is String && hole.isNotEmpty) {
                            label = hole;
                          } else if (hole is Map && hole.isNotEmpty) {
                            label = hole.values.first.toString();
                          } else {
                            label = 'Hole ${i + 1}';
                          }
                          final isSelected = selectedHoleIndex == i;
                          return ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF3F768E) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            selectedColor: Colors.white,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF3F768E) : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) {
                                setState(() {
                                  selectedHoleIndex = i;
                                });
                              },
                          );
                        })
                      ],
                    ),
                  ),
                // Removed course detail data below holes selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Players', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(4, (i) => ChoiceChip(
                          label: Text('Player ${i + 1}'),
                          selected: selectedPlayerCount == i + 1,
                          onSelected: (_) {
                            setState(() {
                              selectedPlayerCount = i + 1;
                            });
                          },
                        )),
                      ),
                      const SizedBox(height: 16),
                      Text('Game Type', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: gameTypes.map((type) => ChoiceChip(
                          label: Text(type),
                          selected: selectedGameType == type,
                          onSelected: (_) {
                            setState(() {
                              selectedGameType = type;
                            });
                          },
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (course['logo'] != null)
            Positioned(
              top: safeHeight(screenHeight * 0.3 - 40, 20),
              right: 16,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipOval(
                  child: Image.asset(
                    course['logo'],
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
