import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'firebase_options.dart';

// -------------------- Data Models --------------------
class College {
  final String id;
  final String name;
  final String location;
  final String description;
  final String contact;
  final String coursesOffered;
  final String infrastructure;
  final String sportsOffered;
  final String mapUrl;
  final String thumbnailUrl;
  final Map<String, List<String>> imageGalleries;
  final List<String> videoUrls;

  College({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.contact,
    required this.coursesOffered,
    required this.infrastructure,
    required this.sportsOffered,
    required this.mapUrl,
    required this.thumbnailUrl,
    required this.imageGalleries,
    required this.videoUrls,
  });

  factory College.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Map<String, List<String>> galleries = {};
    if (data['imageGalleries'] != null) {
      (data['imageGalleries'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          galleries[key] = List<String>.from(value);
        }
      });
    }
    return College(
      id: doc.id,
      name: data['name'] ?? 'No Name Provided',
      location: data['location'] ?? 'No Location Provided',
      description: data['description'] ?? 'No Description Provided',
      contact: data['contact'] ?? 'No Contact Provided',
      coursesOffered: data['coursesOffered'] ?? 'No course information provided.',
      infrastructure: data['infrastructure'] ?? 'No infrastructure information provided.',
      sportsOffered: data['sportsOffered'] ?? 'No sports information provided.',
      mapUrl: data['mapUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      imageGalleries: galleries,
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
    );
  }
}

class FAQ {
  final String question;
  final String answer;
  final List<String> keywords;
  final String? imageUrl;

  FAQ({required this.question, required this.answer, required this.keywords, this.imageUrl});
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imageUrl;

  ChatMessage({required this.text, required this.isUser, this.imageUrl});
}

// -------------------- Main App Initialization --------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CollegeCampusApp());
}

class CollegeCampusApp extends StatelessWidget {
  const CollegeCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollegeCampusAPK',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const FirstPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -------------------- 1. First Page (Welcome Screen) --------------------
class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.indigo.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ..._buildAnimatedIntro(),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CollegesListPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                  ),
                  child: const Text(
                    "Explore Colleges",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedIntro() {
    return AnimationConfiguration.toStaggeredList(
      duration: const Duration(milliseconds: 500),
      childAnimationBuilder: (widget) => SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(child: widget),
      ),
      children: [
        const Icon(Icons.school, size: 100, color: Colors.white),
        const SizedBox(height: 20),
        const Text(
          "College Campus APK",
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "Your ultimate guide to campus life",
          style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// -------------------- 2. Colleges List Page (with Animated List) --------------------
class CollegesListPage extends StatefulWidget {
  const CollegesListPage({super.key});

  @override
  State<CollegesListPage> createState() => _CollegesListPageState();
}

class _CollegesListPageState extends State<CollegesListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Colleges")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() { _searchQuery = value.toLowerCase(); });
              },
              decoration: InputDecoration(
                hintText: 'e.g., "ADGIPS" or "MAIT"',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No colleges found.'));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final collegeName = (doc.data() as Map<String, dynamic>)['name']?.toLowerCase() ?? '';
                  return collegeName.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching colleges found.'));
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final college = College.fromFirestore(filteredDocs[index]);
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 3,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                title: Text(college.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(college.location)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => CollegeDashboardPage(college: college)),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- 3. College Dashboard Page (with Chatbot) --------------------
class CollegeDashboardPage extends StatefulWidget {
  final College college;
  const CollegeDashboardPage({super.key, required this.college});

  @override
  State<CollegeDashboardPage> createState() => _CollegeDashboardPageState();
}

class _CollegeDashboardPageState extends State<CollegeDashboardPage> {
  bool _isChatbotVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.college.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isChatbotVisible = !_isChatbotVisible;
          });
        },
        backgroundColor: Colors.indigo,
        child: Icon(_isChatbotVisible ? Icons.close : Icons.chat_bubble_outline, color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDashboardButton(
                  context,
                  title: "College Info",
                  icon: Icons.info_outline,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollegeInfoPage(college: widget.college))),
                ),
                const SizedBox(height: 16),
                _buildDashboardButton(
                  context,
                  title: "College Images & Videos",
                  icon: Icons.photo_library_outlined,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollegeMediaPage(college: widget.college))),
                ),
                const SizedBox(height: 16),
                _buildDashboardButton(
                  context,
                  title: "College Map",
                  icon: Icons.map_outlined,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollegeMapPage(college: widget.college))),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            bottom: _isChatbotVisible ? 90.0 : -500.0,
            right: 20.0,
            left: 20.0,
            child: ChatbotWidget(
              collegeId: widget.college.id,
              onClose: () {
                setState(() {
                  _isChatbotVisible = false;
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context, {required String title, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade700,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
      ),
    );
  }
}

// -------------------- SMART FAQ Chatbot Widget (with Image Support) --------------------
class ChatbotWidget extends StatefulWidget {
  final String collegeId;
  final VoidCallback onClose;
  const ChatbotWidget({super.key, required this.collegeId, required this.onClose});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  List<FAQ> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
    _addBotMessage("Hello! How can I help you today? Try asking about courses, placements, or fees.");
  }

  Future<void> _loadFAQs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('colleges')
          .doc(widget.collegeId)
          .collection('faqs')
          .get();
      
      _faqs = snapshot.docs.map((doc) {
        return FAQ(
          question: doc.data()['question'] ?? '',
          answer: doc.data()['answer'] ?? '',
          keywords: List<String>.from(doc.data()['keywords'] ?? []),
          imageUrl: doc.data()['imageUrl'],
        );
      }).toList();
    } catch (e) {
      _addBotMessage("Sorry, I couldn't load the FAQ data.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    final userText = text.toLowerCase();
    _textController.clear();

    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
    });

    String responseText = "I'm sorry, I don't have an answer for that. Please try rephrasing your question.";
    String? responseImageUrl;

    if (!_isLoading) {
      for (var faq in _faqs) {
        bool foundMatch = faq.keywords.any((keyword) => userText.contains(keyword.toLowerCase()));
        if (foundMatch) {
          responseText = faq.answer;
          responseImageUrl = faq.imageUrl;
          break;
        }
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage(responseText, imageUrl: responseImageUrl);
    });
  }
  
  void _addBotMessage(String text, {String? imageUrl}) {
    setState(() {
       _messages.insert(0, ChatMessage(text: text, isUser: false, imageUrl: imageUrl));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text("College Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
              ],
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
            const Divider(),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final align = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser ? Colors.indigo.shade400 : Colors.grey.shade200;
    final textColor = message.isUser ? Colors.white : Colors.black87;
    
    return Container(
      alignment: align,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    message.imageUrl!,
                    height: 150,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(message.text, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(hintText: "Ask a question..."),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.indigo),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }
}


// -------------------- 4a. College Info Page (ANIMATED VERSION) --------------------
class CollegeInfoPage extends StatelessWidget {
  final College college;
  const CollegeInfoPage({super.key, required this.college});

  void _showDetailPopup(BuildContext context, String title, String content, IconData icon, bool isMarkdown) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AnimatedDetailPopup(title: title, content: content, icon: icon, isMarkdown: isMarkdown),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("College Info")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (college.thumbnailUrl.isNotEmpty)
              ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(college.thumbnailUrl, height: 220, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: () => _showDetailPopup(context, "Location", college.location, Icons.location_on_outlined, false),
              child: const InfoCard(title: "Location", icon: Icons.location_on_outlined),
            ),
            GestureDetector(
              onTap: () => _showDetailPopup(context, "Contact", college.contact, Icons.phone_outlined, false),
              child: const InfoCard(title: "Contact", icon: Icons.phone_outlined),
            ),
            GestureDetector(
              onTap: () => _showDetailPopup(context, "Courses Offered", college.coursesOffered, Icons.menu_book_outlined, true),
              child: const InfoCard(title: "Courses Offered", icon: Icons.menu_book_outlined),
            ),
            GestureDetector(
              onTap: () => _showDetailPopup(context, "Infrastructure", college.infrastructure, Icons.apartment_outlined, true),
              child: const InfoCard(title: "Infrastructure", icon: Icons.apartment_outlined),
            ),
            GestureDetector(
              onTap: () => _showDetailPopup(context, "Sports Offered", college.sportsOffered, Icons.sports_basketball_outlined, true),
              child: const InfoCard(title: "Sports Offered", icon: Icons.sports_basketball_outlined),
            ),
             GestureDetector(
              onTap: () => _showDetailPopup(context, "Description", college.description, Icons.description_outlined, true),
              child: const InfoCard(title: "Description", icon: Icons.description_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Reusable Styled Info Card (for display) --------------------
class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo.shade700, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.zoom_in, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// -------------------- Animated Detail Pop-up Widget --------------------
class AnimatedDetailPopup extends StatefulWidget {
  final String title;
  final String content;
  final IconData icon;
  final bool isMarkdown;

  const AnimatedDetailPopup({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    this.isMarkdown = true,
  });

  @override
  State<AnimatedDetailPopup> createState() => _AnimatedDetailPopupState();
}

class _AnimatedDetailPopupState extends State<AnimatedDetailPopup> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5);
    
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: Colors.indigo, size: 32),
                    const SizedBox(width: 12),
                    Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const Divider(height: 30),
                Flexible(
                  child: SingleChildScrollView(
                    child: widget.isMarkdown
                        ? MarkdownBody(data: widget.content, styleSheet: MarkdownStyleSheet(p: textStyle))
                        : SelectableText(widget.content, style: textStyle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// -------------------- 4b. College Images & Videos Page (GOOGLE MAPS STYLE) --------------------
class CollegeMediaPage extends StatelessWidget {
  final College college;
  const CollegeMediaPage({super.key, required this.college});

  @override
  Widget build(BuildContext context) {
    final categories = college.imageGalleries.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Images & Videos")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categories.isNotEmpty)
              ...categories.map((category) {
                final imageUrls = college.imageGalleries[category]!;
                final title = category[0].toUpperCase() + category.substring(1); 
                return _buildImageCategoryGrid(context: context, title: title, imageUrls: imageUrls);
              }).toList()
            else
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("No image galleries have been added.")),
              ),
            
            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Videos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            if (college.videoUrls.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: college.videoUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: VideoPlayerWidget(videoUrl: college.videoUrls[index]),
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Text("No videos have been added for this college."),
              ),
          ],
        ),
      ),
    );
  }

  // NEW: This widget builds the Google Maps style 2x2 grid.
  Widget _buildImageCategoryGrid({required BuildContext context, required String title, required List<String> imageUrls}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            // The grid will show a maximum of 4 items
            itemCount: imageUrls.length > 4 ? 4 : imageUrls.length,
            itemBuilder: (context, index) {
              // The special "more" tile logic
              bool isMoreTile = index == 3 && imageUrls.length > 4;

              return GestureDetector(
                onTap: () {
                  if (isMoreTile) {
                    // Navigate to a new page with all images
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FullGalleryPage(title: title, imageUrls: imageUrls)));
                  } else {
                    // Show the pop-up for a single image
                    showDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      builder: (_) => BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: FullScreenImageViewerPopup(imageUrl: imageUrls[index]),
                      ),
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                      ),
                      // If this is the "more" tile, add the overlay
                      if (isMoreTile)
                        Container(
                          alignment: Alignment.center,
                          color: Colors.black.withOpacity(0.6),
                          child: Text(
                            "+${imageUrls.length - 4}",
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// -------------------- NEW: Full Gallery Page --------------------
// This page displays all images for a category when the "+more" tile is tapped.
class FullGalleryPage extends StatelessWidget {
  final String title;
  final List<String> imageUrls;

  const FullGalleryPage({super.key, required this.title, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (_) => BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: FullScreenImageViewerPopup(imageUrl: imageUrls[index]),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}


// -------------------- Full-Screen Image Viewer POP-UP --------------------
class FullScreenImageViewerPopup extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageViewerPopup({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.85),
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// -------------------- Video Player Widget --------------------
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                height: 200,
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ],
    );
  }
}


// -------------------- 4c. College Map Page --------------------
class CollegeMapPage extends StatefulWidget {
  final College college;
  const CollegeMapPage({super.key, required this.college});

  @override
  State<CollegeMapPage> createState() => _CollegeMapPageState();
}

class _CollegeMapPageState extends State<CollegeMapPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.college.mapUrl.isNotEmpty) {
      _controller = WebViewController();

      if (!kIsWeb) {
        _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      }
      
      _controller
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith('https://www.google.com/maps/')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.college.mapUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Map of ${widget.college.name}")),
      body: widget.college.mapUrl.isEmpty
          ? const Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "No map link has been provided for this college.",
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}

