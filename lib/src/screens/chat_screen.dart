import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/message.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/premium_input_field.dart';
import '../widgets/settings_panel.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  bool _isTyping = false;
  final String chatId = 'default_chat';

  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );
    _headerController.forward();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await SupabaseService.getMessages(chatId);
      setState(() {
        _messages.clear();
        _messages.addAll(messages.reversed);
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = ChatMessage(
      text: _controller.text,
      isUser: true,
      timestamp: DateTime.now(),
      chatId: chatId,
    );

    setState(() {
      _messages.insert(0, userMessage);
      _controller.clear();
      _isLoading = true;
      _isTyping = true;
    });

    HapticFeedback.lightImpact();

    try {
      await SupabaseService.sendMessage(userMessage);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }

    // Simulated bot response with typing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isTyping = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final botMessage = ChatMessage(
      text: _getAIResponse(userMessage.text),
      isUser: false,
      timestamp: DateTime.now(),
      chatId: chatId,
    );

    setState(() {
      _messages.insert(0, botMessage);
      _isLoading = false;
    });

    HapticFeedback.mediumImpact();

    try {
      await SupabaseService.sendMessage(botMessage);
    } catch (e) {
      debugPrint('Error sending bot message: $e');
    }
  }

  String _getAIResponse(String userInput) {
    // Simple simulated responses
    final responses = [
      "That's a great question! Let me think about it...\n\nBased on my analysis, here's what I found interesting about your query. The key insight is that understanding the context helps provide better answers.",
      "I'd be happy to help you with that! 🚀\n\nHere's a helpful approach:\n\n**Step 1:** Start by breaking down the problem\n**Step 2:** Identify the key components\n**Step 3:** Build your solution incrementally",
      "Excellent point! Here's what I think:\n\n```dart\nvoid main() {\n  print('Hello, Nika!');\n}\n```\n\nThis pattern can be adapted to your specific needs.",
      "That's an interesting perspective! I've analyzed the possibilities and here are my thoughts on how we can approach this together. Feel free to ask follow-up questions!",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  void _editMessage(int index, String newText) {
    setState(() {
      _messages[index] = _messages[index].copyWith(
        text: newText,
        isEdited: true,
      );
    });
  }

  void _addReaction(int index, String reaction) {
    setState(() {
      _messages[index] = _messages[index].copyWith(
        reactions: [..._messages[index].reactions, reaction],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: SettingsPanel(
        darkMode: context.watch<ThemeProvider>().isDarkMode,
        onDarkModeChanged: (value) {
          context.read<ThemeProvider>().toggleTheme();
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [AppTheme.darkBg, const Color(0xFF1A1A2E)]
                    : [AppTheme.lightBg, const Color(0xFFF0F4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildMessageList(isDark)),
            if (_isTyping) const TypingIndicator(),
            PremiumInputField(
              controller: _controller,
              hintText: 'Ask Nika anything...',
              onSend: _sendMessage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(_headerAnimation),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppTheme.darkSurface.withOpacity(0.8)
                    : Colors.white.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color:
                          isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar and title
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nika Assistant',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isTyping ? 'typing...' : 'Online',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                _isTyping
                                    ? AppTheme.primaryPurple
                                    : (isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // More options
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showOptionsMenu(context, isDark);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.more_vert_rounded,
                      color:
                          isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    if (_messages.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(
          message: _messages[index],
          onEdit: () => _showEditDialog(context, index),
          onReact: (reaction) => _addReaction(index, reaction),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a Conversation',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color:
                  isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything, I\'m here to help!',
            style: TextStyle(
              fontSize: 15,
              color:
                  isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // Suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Explain Flutter', isDark),
              _buildSuggestionChip('Write code', isDark),
              _buildSuggestionChip('Debug my app', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryPurple,
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Clear conversation',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _messages.clear());
                  },
                  isDark: isDark,
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Chat settings',
                  onTap: () {
                    Navigator.pop(context);
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                  isDark: isDark,
                ),
                _buildMenuItem(
                  icon: Icons.share_outlined,
                  label: 'Share conversation',
                  onTap: () {
                    Navigator.pop(context);
                    _shareConversation();
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _shareConversation() {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No messages to share'),
          backgroundColor: AppTheme.primaryPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Nika Chat Conversation');
    buffer.writeln('=' * 30);
    buffer.writeln();

    for (final message in _messages.reversed) {
      final sender = message.isUser ? 'You' : 'Nika';
      final time =
          '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}';
      buffer.writeln('[$time] $sender:');
      buffer.writeln(message.text);
      buffer.writeln();
    }

    Share.share(buffer.toString(), subject: 'My Nika Chat Conversation');
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryPurple).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryPurple, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color:
              iconColor ??
              (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        ),
      ),
      onTap: onTap,
    );
  }

  void _showEditDialog(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: _messages[index].text);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Message',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      filled: true,
                      fillColor:
                          isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      color:
                          isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          _editMessage(index, controller.text);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
