import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final Function()? onEdit;
  final Function(String)? onReact;
  final bool showAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    this.onEdit,
    this.onReact,
    this.showAvatar = true,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = widget.message.isUser;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isUser ? 60 : 16,
            right: isUser ? 16 : 60,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser && widget.showAvatar) ...[
                _buildAvatar(isDark),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onLongPress: () => _showContextMenu(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isUser ? AppTheme.chatBubbleGradient : null,
                        color:
                            isUser
                                ? null
                                : (isDark
                                    ? AppTheme.botMessageDark
                                    : AppTheme.botMessageLight),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(AppTheme.radiusLg),
                          topRight: const Radius.circular(AppTheme.radiusLg),
                          bottomLeft: Radius.circular(
                            isUser ? AppTheme.radiusLg : AppTheme.radiusSm,
                          ),
                          bottomRight: Radius.circular(
                            isUser ? AppTheme.radiusSm : AppTheme.radiusLg,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isUser
                                    ? AppTheme.primaryPurple.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.1),
                            blurRadius: _isHovered ? 20 : 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMessageText(context, isDark, isUser),
                          const SizedBox(height: 6),
                          _buildMetaRow(context, isDark, isUser),
                          if (widget.message.reactions.isNotEmpty)
                            _buildReactions(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isUser && widget.showAvatar) ...[
                const SizedBox(width: 8),
                _buildAvatar(isDark, isUser: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark, {bool isUser = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser ? AppTheme.accentGradient : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: (isUser ? AppTheme.accentPink : AppTheme.primaryPurple)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person_rounded : Icons.auto_awesome,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildMessageText(BuildContext context, bool isDark, bool isUser) {
    return Text(
      widget.message.text,
      style: TextStyle(
        color:
            isUser
                ? Colors.white
                : (isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary),
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, bool isDark, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(widget.message.timestamp),
          style: TextStyle(
            color:
                isUser
                    ? Colors.white.withOpacity(0.7)
                    : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.message.isEdited) ...[
          const SizedBox(width: 6),
          Text(
            '• edited',
            style: TextStyle(
              color:
                  isUser
                      ? Colors.white.withOpacity(0.7)
                      : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReactions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        children:
            widget.message.reactions.map((emoji) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ContextMenuSheet(
            onEdit: widget.onEdit,
            onReact: widget.onReact,
            messageText: widget.message.text,
          ),
    );
  }
}

class _ContextMenuSheet extends StatelessWidget {
  final Function()? onEdit;
  final Function(String)? onReact;
  final String messageText;

  const _ContextMenuSheet({
    this.onEdit,
    this.onReact,
    required this.messageText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          // Reaction picker
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  ['❤️', '👍', '👎', '😄', '🎉', '🔥', '👀']
                      .map((emoji) => _buildReactionButton(context, emoji))
                      .toList(),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
          // Action list
          _buildActionTile(
            context: context,
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: messageText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              );
            },
          ),
          _buildActionTile(
            context: context,
            icon: Icons.edit_rounded,
            label: 'Edit',
            onTap: () {
              Navigator.pop(context);
              onEdit?.call();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildReactionButton(BuildContext context, String emoji) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onReact?.call(emoji);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
