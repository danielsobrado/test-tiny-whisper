import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translation_service.dart';
import '../services/summarization_service.dart';

class TranscriptionDisplayWidget extends StatefulWidget {
  final String transcriptionText;
  final bool showTranslation;
  final Function(String?)? onLanguageDetected;

  const TranscriptionDisplayWidget({
    super.key,
    required this.transcriptionText,
    this.showTranslation = true,
    this.onLanguageDetected,
  });

  @override
  State<TranscriptionDisplayWidget> createState() => _TranscriptionDisplayWidgetState();
}

class _TranscriptionDisplayWidgetState extends State<TranscriptionDisplayWidget> {
  final TranslationService _translationService = TranslationService();
  final SummarizationService _summarizationService = SummarizationService();
  TranslationResult? _translationResult;
  bool _isTranslating = false;
  String? _summary;
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _translationService.initialize();
    _summarizationService.initialize();
  }

  @override
  void didUpdateWidget(TranscriptionDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transcriptionText != oldWidget.transcriptionText) {
      if (widget.transcriptionText.isNotEmpty && widget.showTranslation) {
        _translateText();
      }
      // Clear summary when text changes
      if (_summary != null) {
        setState(() {
          _summary = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _translationService.dispose();
    _summarizationService.dispose();
    super.dispose();
  }

  Future<void> _translateText() async {
    if (widget.transcriptionText.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await _translationService.detectAndTranslate(widget.transcriptionText);
      if (mounted) {
        setState(() {
          _translationResult = result;
          _isTranslating = false;
        });
        
        // Notify parent widget about detected language
        if (widget.onLanguageDetected != null && result.detectedLanguage != null) {
          widget.onLanguageDetected!(result.detectedLanguage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: $e')),
        );
      }
    }
  }

  Future<void> _summarizeText() async {
    if (widget.transcriptionText.isEmpty) return;

    setState(() {
      _isSummarizing = true;
    });

    try {
      // Use the translation result's translated text if available, otherwise use original
      final textToSummarize = _translationResult?.hasTranslation == true
          ? _translationResult!.translatedText!
          : widget.transcriptionText;

      final summary = await _summarizationService.summarizeText(
        textToSummarize,
        maxLength: 100,
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _isSummarizing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSummarizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Summarization error: $e')),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Transcription Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_isTranslating || _isSummarizing) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _isTranslating 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (widget.transcriptionText.isNotEmpty && !_isSummarizing)
              FilledButton.icon(
                onPressed: _summarizeText,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Summarize'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original transcription
                _buildTranscriptionCard(
                  title: _translationResult != null && _translationResult!.needsTranslation
                      ? 'Original (${_translationResult!.displayLanguage})'
                      : 'Transcription',
                  text: widget.transcriptionText,
                  backgroundColor: Colors.grey[100]!,
                  borderColor: Colors.grey[300]!,
                  onCopy: () => _copyToClipboard(context, widget.transcriptionText, 'Original text'),
                ),
                
                // Translation (if available)
                if (_translationResult != null && _translationResult!.hasTranslation) ...[
                  const SizedBox(height: 16),
                  _buildTranscriptionCard(
                    title: 'Translation (English)',
                    text: _translationResult!.translatedText!,
                    backgroundColor: Colors.blue[50]!,
                    borderColor: Colors.blue[200]!,
                    onCopy: () => _copyToClipboard(context, _translationResult!.translatedText!, 'Translation'),
                    icon: Icons.translate,
                  ),
                ],
                
                // Summary (if available)
                if (_summary != null) ...[
                  const SizedBox(height: 16),
                  _buildTranscriptionCard(
                    title: 'AI Summary',
                    text: _summary!,
                    backgroundColor: Colors.amber[50]!,
                    borderColor: Colors.amber[200]!,
                    onCopy: () => _copyToClipboard(context, _summary!, 'Summary'),
                    icon: Icons.auto_awesome_rounded,
                  ),
                ],
                
                // Status info
                if (widget.transcriptionText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildStatusInfo(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptionCard({
    required String title,
    required String text,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onCopy,
    IconData? icon,
  }) {
    final displayText = text.isEmpty ? 'Transcription will appear here...' : text;
    final isEmpty = text.isEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!isEmpty)
                  IconButton(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy to clipboard',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 16,
                color: isEmpty ? Colors.grey[600] : Colors.black,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Length: ${widget.transcriptionText.length} characters',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          
          if (_translationResult != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.language, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _translationResult!.needsTranslation
                      ? 'Language: ${_translationResult!.displayLanguage} → English'
                      : 'Language: ${_translationResult!.displayLanguage ?? 'English'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
          
          if (widget.showTranslation && _translationResult == null && widget.transcriptionText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.translate, size: 16, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Translation pending...',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}