import 'package:flutter/material.dart';

// Reaction data
class Reaction {
  final String name;
  final IconData icon;
  final Color color;
  const Reaction(this.name, this.icon, this.color);
}

const List<Reaction> reactions = [
  Reaction('Like', Icons.thumb_up_alt_rounded, Color(0xFF1877F2)),
  Reaction('Love', Icons.favorite_rounded, Color(0xFFE0245E)),
  Reaction('Haha', Icons.emoji_emotions_rounded, Color(0xFFFFC107)),
  Reaction('Wow', Icons.emoji_objects_rounded, Color(0xFF8BC34A)),
  Reaction('Sad', Icons.sentiment_dissatisfied_rounded, Color(0xFF607D8B)),
  Reaction('Angry', Icons.sentiment_very_dissatisfied_rounded, Color(0xFFF44336)),
];

class PostActionBar extends StatefulWidget {
  final String? selectedReaction; // e.g. 'Like', 'Love', etc.
  final Function(String) onReact;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool isSaved;
  final VoidCallback onSave;

  const PostActionBar({
    Key? key,
    required this.selectedReaction,
    required this.onReact,
    required this.onComment,
    required this.onShare,
    required this.isSaved,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PostActionBar> createState() => _PostActionBarState();
}

class _PostActionBarState extends State<PostActionBar> {
  bool _showReactions = false;
  OverlayEntry? _overlayEntry;

  void _showReactionPicker(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 10,
        top: position.dy - 70,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: reactions.map((reaction) {
                  return GestureDetector(
                    onTap: () {
                      widget.onReact(reaction.name);
                      _hideReactionPicker();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(reaction.icon, color: reaction.color, size: 30),
                          Text(reaction.name, style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context)?.insert(_overlayEntry!);
    setState(() => _showReactions = true);
  }

  void _hideReactionPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _showReactions = false);
  }

  @override
  void dispose() {
    _hideReactionPicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = reactions.firstWhere(
      (r) => r.name == widget.selectedReaction,
      orElse: () => reactions[0],
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Like/React Button (centered, with reaction picker)
          GestureDetector(
            onTap: () {
              if (_showReactions) {
                _hideReactionPicker();
              } else {
                _showReactionPicker(context);
              }
            },
            child: Column(
              children: [
                Icon(selected.icon, color: selected.color, size: 30),
                Text(selected.name, style: TextStyle(fontSize: 12, color: selected.color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Comment Button (right of like)
          GestureDetector(
            onTap: widget.onComment,
            child: Column(
              children: [
                Icon(Icons.mode_comment_rounded, color: Color(0xFF4F8EFF), size: 28),
                Text('Comment', style: TextStyle(fontSize: 12, color: Color(0xFF4F8EFF))),
              ],
            ),
          ),
          // Share Button (rightmost)
          GestureDetector(
            onTap: widget.onShare,
            child: Column(
              children: [
                Icon(Icons.ios_share_rounded, color: Color(0xFF34C759), size: 28),
                Text('Share', style: TextStyle(fontSize: 12, color: Color(0xFF34C759))),
              ],
            ),
          ),
          // Save Button (floating right)
          GestureDetector(
            onTap: widget.onSave,
            child: Column(
              children: [
                Icon(
                  widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: widget.isSaved ? Colors.amber[800] : Colors.grey[600],
                  size: 28,
                ),
                Text(widget.isSaved ? 'Saved' : 'Save', style: TextStyle(fontSize: 12, color: widget.isSaved ? Colors.amber[800] : Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 