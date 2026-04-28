import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shared_prefs_helper.dart';

/// Manual code entry screen — fallback when QR scanning is not possible.
///
/// Returns the validated [eventId] via [Navigator.pop] when confirmed.
class ManualCodeScreen extends StatefulWidget {
  const ManualCodeScreen({super.key});

  @override
  State<ManualCodeScreen> createState() => _ManualCodeScreenState();
}

class _ManualCodeScreenState extends State<ManualCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Inserisci il codice evento';
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value.trim())) {
      return 'Il codice deve essere alfanumerico (lettere, numeri, - e _)';
    }
    return null;
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final eventId = _controller.text.trim();

    // Save to recents before navigating
    await SharedPrefsHelper.addRecentEvent(eventId);

    if (mounted) {
      Navigator.of(context).pop(eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inserisci codice'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Icon + title
                const Icon(
                  Icons.keyboard_rounded,
                  size: 52,
                  color: AppTheme.stageAmber,
                ),
                const SizedBox(height: 20),
                Text(
                  'Codice evento',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Trovi il codice sul materiale dell\'evento o sullo schermo all\'ingresso.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Text field
                TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  validator: _validate,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _confirm(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Codice evento',
                    hintText: 'es. EVT2024ABC',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                // Confirm button
                FilledButton(
                  onPressed: _loading ? null : _confirm,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Conferma'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
