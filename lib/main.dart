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

  @override
  void initState() {
    super.initState();
    _checkLogin();
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
      home: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loggedIn
              ? MainNavigation(onLogout: _onLogout)
              : LoginPage(onLogin: _onLogin),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final VoidCallback? onLogout;
  const MainNavigation({super.key, this.onLogout});

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
      PlayPage(),
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
  const PlayPage({super.key});
  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> filteredCourses = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> recentCourses = [];
  bool hasSearched = false;
  bool isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadRecentCourses();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  Future<void> _loadCourses() async {
    final data = await rootBundle.loadString('assets/golf_courses.json');
    final List<dynamic> jsonList = json.decode(data);
    setState(() {
      courses = jsonList.cast<Map<String, dynamic>>();
      filteredCourses = [];
    });
    await _loadRecentCourses();
  }

  Future<void> _loadRecentCourses() async {
    // Use SharedPreferences for persistence
    final prefs = await SharedPreferences.getInstance();
    final recentIds = prefs.getStringList('recent_course_ids') ?? [];
    setState(() {
      recentCourses = recentIds.map((id) => courses.firstWhere(
        (course) => course['id'].toString() == id,
        orElse: () => {},
      )).where((course) => course.isNotEmpty).take(5).toList();
    });
  }

  Future<void> _addRecentCourse(Map<String, dynamic> course) async {
    final prefs = await SharedPreferences.getInstance();
    final recentIds = prefs.getStringList('recent_course_ids') ?? [];
    final id = course['id'].toString();
    recentIds.remove(id); // Remove if already exists
    recentIds.insert(0, id); // Add to front
    while (recentIds.length > 5) {
      recentIds.removeLast();
    }
    await prefs.setStringList('recent_course_ids', recentIds);
    _loadRecentCourses();
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            const SizedBox(height: 16),
            Expanded(
              child: (isSearchFocused && _searchController.text.isNotEmpty)
                  ? ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CourseDetailPage(course: course),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    )
                  : (!isSearchFocused && _searchController.text.isEmpty)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recent Searches', style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: recentCourses.length,
                                itemBuilder: (context, index) {
                                  final course = recentCourses[index];
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
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CourseDetailPage(course: course),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Container(),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailPage extends StatelessWidget {
  final Map<String, dynamic> course;
  const CourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final tags = course['tags'] as Map<String, dynamic>? ?? {};
    final detailTextStyle = Theme.of(context).textTheme.bodyMedium;
    final mainImage = course['mainImage'];
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mainImage != null && mainImage.isNotEmpty)
                Image.asset(
                  mainImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: screenHeight * 0.3,
                ),
              SizedBox(height: 40), // Space for logo overlay
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        Row(
                          children: [
                            // Removed SizedBox(width: 76), so course name starts at left
                            Expanded(
                              child: Text(course['name'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Latitude: ${course['lat'] ?? "-"}', style: detailTextStyle),
                        Text('Longitude: ${course['lon'] ?? "-"}', style: detailTextStyle),
                        Text('Type: ${course['type'] ?? "-"}', style: detailTextStyle),
                        ...tags.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('${entry.key}: ${entry.value}', style: detailTextStyle),
                          );
                        }).toList(),
                        ...course.keys.where((k) => k != 'id' && k != 'type' && k != 'name' && k != 'lat' && k != 'lon' && k != 'tags' && k != 'logo' && k != 'mainImage').map((k) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('$k: ${course[k]}', style: detailTextStyle),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (course['logo'] != null)
            Positioned(
              top: screenHeight * 0.3 - 40,
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
