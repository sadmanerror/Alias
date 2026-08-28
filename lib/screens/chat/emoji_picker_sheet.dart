import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

class EmojiPickerSheet extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onEmojiSelected;

  const EmojiPickerSheet({
    super.key,
    required this.controller,
    required this.onEmojiSelected,
  });

  static const Color primarySageGreen = Color(0xFF8DA399);
  static const Color offWhite = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          onEmojiSelected(emoji.emoji);
        },
        textEditingController: controller,
        config: Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: offWhite,
            columns: 7,
            emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
          ),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: const CategoryViewConfig(
            indicatorColor: primarySageGreen,
            iconColorSelected: primarySageGreen,
            backgroundColor: offWhite,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            backgroundColor: offWhite,
            buttonColor: offWhite,
            buttonIconColor: primarySageGreen,
          ),
          searchViewConfig: const SearchViewConfig(
            backgroundColor: offWhite,
            buttonIconColor: primarySageGreen,
          ),
        ),
      ),
    );
  }
}
