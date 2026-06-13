import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  runApp(PakistanLiveTVApp());
}

class PakistanLiveTVApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pakistan Live TV',
      theme: ThemeData(
        primaryColor: Color(0xFF006633),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF006633),
          primary: Color(0xFF006633),
        ),
        scaffoldBackgroundColor: Color(0xFF0A1A0F),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF006633),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future.delayed(Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isFirstTime ? OnboardingScreen() : HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF006633), Color(0xFF004D26)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Flag_of_Pakistan.svg/120px-Flag_of_Pakistan.svg.png',
                  height: 80,
                  width: 80,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.tv,
                    size: 80,
                    color: Color(0xFF006633),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text('Pakistan Live TV',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Text('Watch All Pakistani Channels',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 40),
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {'title': 'Watch Live TV', 'desc': 'Stream all your favorite Pakistani channels live', 
     'icon': Icons.live_tv, 'color': Color(0xFF00A86B)},
    {'title': 'News Channels', 'desc': 'Stay updated with 24/7 news from Geo, ARY, and more', 
     'icon': Icons.newspaper, 'color': Color(0xFF00A86B)},
    {'title': 'Entertainment', 'desc': 'Watch dramas, shows, and entertainment programs', 
     'icon': Icons.movie, 'color': Color(0xFF00A86B)},
    {'title': 'Sports', 'desc': 'Live cricket matches and sports coverage', 
     'icon': Icons.sports_cricket, 'color': Color(0xFF00A86B)},
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => HomeScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: page['color'].withOpacity(0.1), 
                          shape: BoxShape.circle
                        ),
                        child: Icon(page['icon'], size: 100, color: page['color']),
                      ),
                      SizedBox(height: 48),
                      Text(page['title'], 
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      Text(page['desc'], 
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      color: _currentPage == index ? Color(0xFF006633) : Colors.grey[300],
                    ),
                  )),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _currentPage == _pages.length - 1 
                      ? _complete() 
                      : _pageController.nextPage(
                          duration: Duration(milliseconds: 300), 
                          curve: Curves.easeInOut
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF006633),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    ChannelsScreen(),
    CategoriesScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF006633),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'Channels'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class ChannelsScreen extends StatefulWidget {
  @override
  _ChannelsScreenState createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  List<Map<String, String>> _channels = [];
  List<Map<String, String>> _filteredChannels = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _searchController.addListener(_filterChannels);
  }

  void _loadChannels() {
    _channels = [
      // NEWS CHANNELS
      {'name': 'Geo News', 'category': 'News', 'url': 'https://www.geo.tv/live-tv', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/6/6b/Geo_News_logo.svg/200px-Geo_News_logo.svg.png'},
      {'name': 'ARY News', 'category': 'News', 'url': 'https://live.arynews.tv/', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/ARY_News_Logo.png/200px-ARY_News_Logo.png'},
      {'name': 'Express News', 'category': 'News', 'url': 'https://www.express.pk/livetv', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/5/5c/Express_News_Logo.png/200px-Express_News_Logo.png'},
      {'name': 'Samaa TV', 'category': 'News', 'url': 'https://www.samaa.tv/live', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/5/5d/Samaa_TV_logo.png/200px-Samaa_TV_logo.png'},
      {'name': 'Dunya News', 'category': 'News', 'url': 'https://dunyanews.tv/live', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/a/ab/Dunya_News_Logo.png/200px-Dunya_News_Logo.png'},
      {'name': '92 News', 'category': 'News', 'url': 'https://92newshd.tv/live', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/4/45/92_News_HD_logo.png/200px-92_News_HD_logo.png'},
      {'name': 'GNN', 'category': 'News', 'url': 'https://gnn.tv/live', 'icon': 'https://gnn.tv/assets/images/gnn-logo.png'},
      {'name': 'Bol News', 'category': 'News', 'url': 'https://www.bolnews.com/live-tv', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/5/54/BOL_News_Logo.png/200px-BOL_News_Logo.png'},
      
      // ENTERTAINMENT CHANNELS
      {'name': 'Hum TV', 'category': 'Entertainment', 'url': 'https://www.hum.tv/live', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/Hum_TV_logo.png/200px-Hum_TV_logo.png'},
      {'name': 'ARY Digital', 'category': 'Entertainment', 'url': 'https://arydigital.tv/live', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/ARY_Digital_logo.png/200px-ARY_Digital_logo.png'},
      {'name': 'Geo Entertainment', 'category': 'Entertainment', 'url': 'https://www.geo.tv/geo-entertainment', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/6/6b/Geo_News_logo.svg/200px-Geo_News_logo.svg.png'},
      {'name': 'A-Plus', 'category': 'Entertainment', 'url': 'https://a-plus.tv/live', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/b/b5/A-Plus_Logo.png/200px-A-Plus_Logo.png'},
      {'name': 'BOL Entertainment', 'category': 'Entertainment', 'url': 'https://www.bolnetwork.com/live', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/5/54/BOL_News_Logo.png/200px-BOL_News_Logo.png'},
      {'name': 'TV One', 'category': 'Entertainment', 'url': 'https://www.tvone.pk/live', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/e/e1/TV_One_Logo.png/200px-TV_One_Logo.png'},
      
      // SPORTS CHANNELS
      {'name': 'Ten Sports', 'category': 'Sports', 'url': 'https://tensports.com/live', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d7/Ten_Sports_logo.svg/200px-Ten_Sports_logo.svg.png'},
      {'name': 'PTV Sports', 'category': 'Sports', 'url': 'https://sports.ptv.com.pk/live', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/PTV_Sports_logo.png/200px-PTV_Sports_logo.png'},
      {'name': 'A-Sports', 'category': 'Sports', 'url': 'https://a-sports.tv/live', 'icon': 'https://a-sports.tv/assets/images/logo.png'},
      
      // MUSIC CHANNELS
      {'name': '8XM', 'category': 'Music', 'url': 'https://8xm.tv/live', 'icon': 'https://upload.wikimedia.org/wikipedia/en/thumb/9/9b/8XM_logo.png/200px-8XM_logo.png'},
      {'name': 'Oxygene', 'category': 'Music', 'url': 'https://oxygene.tv/live', 'icon': 'https://oxygene.tv/assets/images/logo.png'},
      
      // KIDS CHANNELS
      {'name': 'Cartoon Network', 'category': 'Kids', 'url': 'https://www.cartoonnetwork.com.pk/live', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Cartoon_Network_2010_logo.svg/200px-Cartoon_Network_2010_logo.svg.png'},
      {'name': 'Nickelodeon', 'category': 'Kids', 'url': 'https://www.nickelodeon.pk/live', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Nickelodeon_logo_2023.svg/200px-Nickelodeon_logo_2023.svg.png'},
      
      // PTV
      {'name': 'PTV Home', 'category': 'National', 'url': 'https://www.ptv.com.pk/live', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/PTV_Home_logo.png/200px-PTV_Home_logo.png'},
      {'name': 'PTV News', 'category': 'National', 'url': 'https://news.ptv.com.pk/live', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/PTV_News_logo.png/200px-PTV_News_logo.png'},
    ];
    _filteredChannels = List.from(_channels);
  }

  void _filterChannels() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredChannels = List.from(_channels);
      } else {
        _filteredChannels = _channels.where((channel) {
          return channel['name']!.toLowerCase().contains(_searchQuery) ||
                 channel['category']!.toLowerCase().contains(_searchQuery);
        }).toList();
      }
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
        title: Text('Pakistan Live TV'),
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search channels...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredChannels.length,
              itemBuilder: (context, index) {
                final channel = _filteredChannels[index];
                return _buildChannelCard(channel);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard(Map<String, String> channel) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              channelName: channel['name']!,
              channelUrl: channel['url']!,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.tv, size: 50, color: Color(0xFF006633)),
            ),
            SizedBox(height: 12),
            Text(
              channel['name']!,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                channel['category']!,
                style: TextStyle(fontSize: 10, color: Color(0xFF006633)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All Channels', 'icon': Icons.tv, 'color': Color(0xFF006633)},
    {'name': 'News', 'icon': Icons.newspaper, 'color': Color(0xFFE53935)},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Color(0xFF7B1FA2)},
    {'name': 'Sports', 'icon': Icons.sports_cricket, 'color': Color(0xFFF57C00)},
    {'name': 'Music', 'icon': Icons.music_note, 'color': Color(0xFFE91E63)},
    {'name': 'Kids', 'icon': Icons.child_care, 'color': Color(0xFF00ACC1)},
    {'name': 'National', 'icon': Icons.flag, 'color': Color(0xFF43A047)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Categories'), elevation: 0),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryChannelsScreen(
                    categoryName: category['name']!,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [category['color'], category['color'].withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category['icon'], size: 50, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    category['name']!,
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryChannelsScreen extends StatelessWidget {
  final String categoryName;

  CategoryChannelsScreen({required this.categoryName});

  List<Map<String, String>> _getChannelsByCategory() {
    List<Map<String, String>> allChannels = [
      {'name': 'Geo News', 'category': 'News', 'url': 'https://www.geo.tv/live-tv'},
      {'name': 'ARY News', 'category': 'News', 'url': 'https://live.arynews.tv/'},
      {'name': 'Express News', 'category': 'News', 'url': 'https://www.express.pk/livetv'},
      {'name': 'Samaa TV', 'category': 'News', 'url': 'https://www.samaa.tv/live'},
      {'name': 'Hum TV', 'category': 'Entertainment', 'url': 'https://www.hum.tv/live'},
      {'name': 'ARY Digital', 'category': 'Entertainment', 'url': 'https://arydigital.tv/live'},
      {'name': 'Geo Entertainment', 'category': 'Entertainment', 'url': 'https://www.geo.tv/geo-entertainment'},
      {'name': 'Ten Sports', 'category': 'Sports', 'url': 'https://tensports.com/live'},
      {'name': 'PTV Sports', 'category': 'Sports', 'url': 'https://sports.ptv.com.pk/live'},
      {'name': '8XM', 'category': 'Music', 'url': 'https://8xm.tv/live'},
      {'name': 'Cartoon Network', 'category': 'Kids', 'url': 'https://www.cartoonnetwork.com.pk/live'},
      {'name': 'PTV Home', 'category': 'National', 'url': 'https://www.ptv.com.pk/live'},
    ];

    if (categoryName == 'All Channels') {
      return allChannels;
    }
    return allChannels.where((c) => c['category'] == categoryName).toList();
  }

  @override
  Widget build(BuildContext context) {
    final channels = _getChannelsByCategory();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName Channels'),
        elevation: 0,
      ),
      body: channels.isEmpty
          ? Center(child: Text('No channels found in this category'))
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          channelName: channel['name']!,
                          channelUrl: channel['url']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Icon(Icons.tv, size: 40, color: Color(0xFF006633)),
                        ),
                        SizedBox(height: 12),
                        Text(
                          channel['name']!,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            channel['category']!,
                            style: TextStyle(fontSize: 10, color: Color(0xFF006633)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String channelName;
  final String channelUrl;

  PlayerScreen({required this.channelName, required this.channelUrl});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initWebView();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.channelUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isConnected)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No internet connection. Please check your network.',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006633)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading ${widget.channelName}...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, String>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    // For demo purposes, adding sample favorites
    _favorites = [
      {'name': 'Geo News', 'category': 'News', 'url': 'https://www.geo.tv/live-tv'},
      {'name': 'Hum TV', 'category': 'Entertainment', 'url': 'https://www.hum.tv/live'},
    ];
  }

  void _removeFavorite(int index) {
    setState(() {
      _favorites.removeAt(index);
    });
    // Save to shared preferences here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites'),
        elevation: 0,
      ),
      body: _favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorite channels yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any channel to add to favorites',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final channel = _favorites[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.tv, color: Color(0xFF006633)),
                    ),
                    title: Text(channel['name']!),
                    subtitle: Text(channel['category']!),
                    trailing: IconButton(
                      icon: Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _removeFavorite(index),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            channelName: channel['name']!,
                            channelUrl: channel['url']!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedQuality = 'Auto';
  final List<String> _qualities = ['Auto', 'HD', 'SD'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Notifications'),
                  subtitle: Text('Receive channel updates and news alerts'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: Color(0xFF006633),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Dark Mode'),
                  subtitle: Text('Switch to dark theme'),
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                  activeColor: Color(0xFF006633),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Video Quality'),
                  subtitle: Text('Current: $_selectedQuality'),
                  trailing: DropdownButton<String>(
                    value: _selectedQuality,
                    items: _qualities.map((String quality) {
                      return DropdownMenuItem<String>(
                        value: quality,
                        child: Text(quality),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedQuality = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info, color: Color(0xFF006633)),
                  title: Text('About'),
                  subtitle: Text('Pakistan Live TV App'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: Color(0xFF006633)),
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    _showPrivacyDialog();
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.share, color: Color(0xFF006633)),
                  title: Text('Share App'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // Share functionality
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.star, color: Color(0xFF006633)),
                  title: Text('Rate Us'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // Rate functionality
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  'Pakistan Live TV',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Watch all your favorite Pakistani channels live, anytime, anywhere.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Pakistan Live TV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tv, size: 50, color: Color(0xFF006633)),
            SizedBox(height: 16),
            Text(
              'Pakistan Live TV brings you all the popular Pakistani channels in one place. '
              'Watch news, entertainment, sports, music, and kids channels live.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'We respect your privacy. This app does not collect any personal information. '
            'All channel streams are provided by their respective owners. '
            'This app only provides links to publicly available streams.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}