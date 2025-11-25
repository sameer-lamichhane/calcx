import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/image_service.dart';

class MessageBubble extends StatefulWidget {
  final String text;
  final String senderId;
  final DateTime? timestamp;
  final bool isCurrentUser;
  final String? imageHash;
  final String? messageType;
  final List<String>? seenBy;
  final String? otherUserId;

  const MessageBubble({
    super.key,
    required this.text,
    required this.senderId,
    this.timestamp,
    this.isCurrentUser = false,
    this.imageHash,
    this.messageType,
    this.seenBy,
    this.otherUserId,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final _imageService = ImageService();
  String? _imageData;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.messageType == 'image' && widget.imageHash != null) {
      _loadImage();
    }
  }

  bool _isSeen() {
    if (widget.seenBy == null || widget.otherUserId == null) return false;
    if (!widget.isCurrentUser) return false;
    return widget.seenBy!.contains(widget.otherUserId);
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoadingImage = true;
    });
    
    final base64Data = await _imageService.getImageDataByHash(widget.imageHash!);
    if (mounted) {
      setState(() {
        _imageData = base64Data;
        _isLoadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.messageType == 'image' && widget.imageHash != null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            widget.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade200,
              child: Text(
                widget.text.isNotEmpty ? widget.text[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: isImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isCurrentUser
                    ? Colors.blue.shade700
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(widget.isCurrentUser ? 20 : 4),
                  bottomRight: Radius.circular(widget.isCurrentUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isImage) ...[
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: _isLoadingImage
                          ? Container(
                              height: 200,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _imageData != null
                              ? GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors.black87,
                                      builder: (context) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: EdgeInsets.zero,
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: InteractiveViewer(
                                                minScale: 0.5,
                                                maxScale: 4.0,
                                                child: Image.memory(
                                                  base64Decode(_imageData!),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 40,
                                              right: 20,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 40,
                                              right: 20,
                                              child: FloatingActionButton(
                                                backgroundColor: Colors.white.withOpacity(0.9),
                                                onPressed: () async {
                                                  try {
                                                    final Uint8List imageBytes = base64Decode(_imageData!);
                                                    final directory = await getTemporaryDirectory();
                                                    final imagePath = '${directory.path}/calcx_image_${DateTime.now().millisecondsSinceEpoch}.png';
                                                    final file = File(imagePath);
                                                    await file.writeAsBytes(imageBytes);
                                                    
                                                    await Share.shareXFiles(
                                                      [XFile(imagePath)],
                                                      text: 'Image from Calcx',
                                                    );
                                                    
                                                    if (mounted && context.mounted) {
                                                      Navigator.pop(context);
                                                    }
                                                  } catch (e) {
                                                    if (mounted && context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Failed to save image: $e'),
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: const Icon(Icons.download, color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                      maxWidth: 250,
                                    ),
                                    child: Image.memory(
                                      base64Decode(_imageData!),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 200,
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                    ),
                    if (widget.text.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            color: widget.isCurrentUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.isCurrentUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.timestamp != null) ...[
                        Padding(
                          padding: EdgeInsets.only(
                            left: isImage && widget.text.isEmpty ? 12 : 0,
                            right: isImage && widget.text.isEmpty ? 12 : 0,
                            top: 4,
                            bottom: isImage ? 12 : 0,
                          ),
                          child: Text(
                            DateFormat('HH:mm').format(widget.timestamp!),
                            style: TextStyle(
                              color: widget.isCurrentUser
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      if (widget.isCurrentUser && widget.otherUserId != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _isSeen() ? Icons.done_all : Icons.done,
                          size: 14,
                          color: _isSeen() ? Colors.blue.shade300 : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade200,
              child: Text(
                widget.text.isNotEmpty ? widget.text[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
