import 'package:flutter/material.dart';
import '../services/summarization_service.dart';

class SummarizationPromptsWidget extends StatefulWidget {
  const SummarizationPromptsWidget({super.key});

  @override
  State<SummarizationPromptsWidget> createState() => _SummarizationPromptsWidgetState();
}

class _SummarizationPromptsWidgetState extends State<SummarizationPromptsWidget> {
  final SummarizationService _summarizationService = SummarizationService();
  String _selectedPromptKey = 'bullet_points';
  
  @override
  void initState() {
    super.initState();
    _loadSelectedPrompt();
  }

  @override
  void dispose() {
    _summarizationService.dispose();
    super.dispose();
  }

  void _loadSelectedPrompt() {
    final selectedPrompt = _summarizationService.getSelectedPromptKey();
    setState(() {
      _selectedPromptKey = selectedPrompt;
    });
  }

  void _selectPrompt(String promptKey) {
    _summarizationService.selectPrompt(promptKey);
    setState(() {
      _selectedPromptKey = promptKey;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${SummarizationService.availablePrompts[promptKey]?.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: colorScheme.onSecondaryContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Summarization Styles',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose how you want your text to be summarized. Different styles work better for different types of content.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.onSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active: ${SummarizationService.availablePrompts[_selectedPromptKey]?.name ?? "Default"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Prompts List
          Text(
            'Available Summarization Styles',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          ...SummarizationService.availablePrompts.entries.map((entry) {
            final promptKey = entry.key;
            final promptInfo = entry.value;
            final isSelected = _selectedPromptKey == promptKey;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected 
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      promptInfo.icon,
                      color: isSelected 
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          promptInfo.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                      ),
                      if (isSelected) ...[ 
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        promptInfo.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Example output
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview_rounded,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Example Output:',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              promptInfo.example,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Best for section
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Best for: ${promptInfo.bestFor}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  onTap: isSelected ? null : () => _selectPrompt(promptKey),
                  
                  trailing: isSelected 
                      ? Icon(
                          Icons.radio_button_checked,
                          color: colorScheme.primary,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Tips Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for Better Summaries',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ...[
                    'Longer texts (>100 words) generally produce better summaries',
                    'Choose bullet points for meeting notes and lists',
                    'Use single sentence for quick overviews and social media',
                    'Technical summary works best for documentation and guides',
                    'Key insights style highlights the most important information',
                  ].map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}